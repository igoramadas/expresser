# EXPRESSER APP
# -----------------------------------------------------------------------------
# The Express app server, with built-in sockets, firewall and New Relic integration.
# <!--
# @see Firewall
# @see Sockets
# @see Settings.app
# -->
class App

    express = require "express"
    fs = require "fs"
    http = require "http"
    https = require "https"
    lodash = require "lodash"
    os = require "os"

    # Internal modules will be set on `init`.
    firewall = null
    logger = null
    settings = null
    sockets = null
    utils = null

    # @property [Object] Exposes the Express HTTP or HTTPS `server` object.
    server: null

    # @property [Array<Object>] Array of additional middlewares to be use by the Express server. Please note that if you're adding middlewares manually you must do it BEFORE calling `init`.
    extraMiddlewares: []

    # Current node environment and HTTP server handler are set on init.
    nodeEnv = null
    httpServer = null

    # INIT
    # --------------------------------------------------------------------------

    # Init the Express server. If New Relic settings are set it will automatically
    # require and use the `newrelic` module. Firewall and Sockets modules will be
    # used only if enabled on the settings.
    # @param [Array] arrExtraMiddlewares Array with extra middlewares to be added on init, optional.
    init: (arrExtraMiddlewares) =>
        settings = require "./settings.coffee"
        utils = require "./utils.coffee"
        nodeEnv = process.env.NODE_ENV

        # Init New Relic, if enabled.
        @initNewRelic()

        # Require logger.
        logger = require "./logger.coffee"
        logger.debug "App", "init", arrExtraMiddlewares

        # Set error handler, configure Express server and start it.
        @setErrorHandler()
        @configureServer()
        @startServer()

    # Init new Relic, depending on its settings (enabled, appName and LicenseKey).
    initNewRelic: =>
        newRelicEnabled = settings.newRelic.enabled
        newRelicAppName = process.env.NEW_RELIC_APP_NAME or settings.newRelic.appName
        newRelicLicenseKey = process.env.NEW_RELIC_LICENSE_KEY or settings.newRelic.licenseKey

        # Check if New Relic settings are available, and if so, start the New Relic agent.
        if newRelicEnabled and newRelicAppName? and newRelicAppName isnt "" and newRelicLicenseKey? and newRelicLicenseKey isnt ""
            console.log "App", "Embeding New Relic agent for #{newRelicAppName}..."
            require "newrelic"

    # Log proccess termination to the console. This will force flush any buffered logs to disk.
    # Do not log the exit if running under test environment.
    setErrorHandler: =>
        process.on "exit", (sig) ->
            if nodeEnv? and nodeEnv.indexOf("test") < 0
                console.warn "App", "Terminating Expresser app...", Date(Date.now()), sig
            try
                logger.flushLocal()
            catch err
                console.warn "App", "Could not flush buffered logs to disk."

    # Configure the server. Set views, options, use Express modules, etc.
    configureServer: =>
        @server = express()

        @server.configure =>
            settings.updateFromPaaS() if settings.app.paas

            # Set view options, use Jade for HTML templates.
            @server.set "views", settings.path.viewsDir
            @server.set "view engine", settings.app.viewEngine
            @server.set "view options", { layout: false }

            # If debug is on, log requests to the console.
            if settings.general.debug
                @server.use (req, res, next) =>
                    ip = utils.getClientIP req
                    method = req.method
                    url = req.url

                    # Check if request flash is present before logging.
                    if req.flash? and lodash.isFunction req.flash
                        console.log "Request from #{ip}", method, url, req.flash()
                    else
                        console.log "Request from #{ip}", method, url
                    next() if next?

            # Enable firewall?
            if settings.firewall.enabled
                firewall = require "./firewall.coffee"
                firewall.init @server

            # Use Express basic handlers.
            @server.use express.bodyParser()
            @server.use express.cookieParser settings.app.cookieSecret
            @server.use express.session {secret: settings.app.sessionSecret}
            @server.use express.compress()
            @server.use express.methodOverride()
            @server.use express["static"] settings.path.publicDir

            # Fix connect assets helper context.
            connectAssetsOptions = settings.app.connectAssets
            connectAssetsOptions.helperContext = @server.locals

            # Connect assets and dynamic compiling.
            ConnectAssets = (require "connect-assets") connectAssetsOptions
            @server.use ConnectAssets

            # Check for extra middlewares to be added.
            if arrExtraMiddlewares?
                if lodash.isArray arrExtraMiddlewares
                    @extraMiddlewares.push mw for mw in arrExtraMiddlewares
                else
                    @extraMiddlewares.push arrExtraMiddlewares

            # Add more middlewares, if any (for example passport for authentication).
            if @extraMiddlewares.length > 0
                @server.use mw for mw in @extraMiddlewares

            # Set Express router.
            @server.use @server.router

            # Enable sockets?
            if settings.sockets.enabled
                sockets = require "./sockets.coffee"
                sockets.init httpServer

        # Configure development environment to dump exceptions and show stack.
        @server.configure "development", =>
            @server.use express.errorHandler {dumpExceptions: true, showStack: true}

        # Configure production environment.
        @server.configure "production", =>
            @server.use express.errorHandler()

    # Start the server using HTTP or HTTPS, depending on the settings.
    startServer: =>
        if settings.app.ssl and settings.path.sslKeyFile? and settings.path.sslCertFile?
            sslKeyFile = utils.getFilePath settings.path.sslKeyFile
            sslCertFile = utils.getFilePath settings.path.sslCertFile

            # Certificate files were found? Proceed, otherwise alert the user and throw an error.
            if sslKeyFile? and sslCertFile?
                sslKey = fs.readFileSync sslKeyFile, {encoding: settings.general.encoding}
                sslCert = fs.readFileSync sslCertFile, {encoding: settings.general.encoding}
                sslOptions = {key: sslKey, cert: sslCert}
                httpServer = https.createServer sslOptions, @server
            else
                logger.error "App", "init", "Cannot find certificate files.", settings.path.sslKeyFile, settings.path.sslCertFile
                throw new Error "The certificate files could not be found. Please check the 'Path.sslKeyFile' and 'Path.sslCertFile' settings."
        else
            httpServer = http.createServer @server

        # Start the server and log output.
        if settings.app.ip? and settings.app.ip isnt ""
            httpServer.listen settings.app.port, settings.app.ip
            logger.info "App #{settings.general.appTitle} started!", settings.app.ip, settings.app.port
        else
            httpServer.listen settings.app.port
            logger.info "App #{settings.general.appTitle} started!", settings.app.port

    # HELPER AND UTILS
    # --------------------------------------------------------------------------

    # Helper to render pages. The request, response and view are mandatory,
    # and the options argument is optional.
    # @param [Object] req The request object.
    # @param [Object] res The response object.
    # @param [String] view The view name.
    # @param [Object] options Options passed to the view, optional.
    renderView: (req, res, view, options) =>
        options = {} if not options?
        options.device = utils.getClientDevice req
        options.title = settings.general.appTitle if not options.title?
        res.render view, options
        logger.debug "App", "Render", view, options

    # Helper to send error responses. When the server can't return a valid result,
    # send an error response with the specified status code.
    # @param [Object] req The response object.
    # @param [String] message The message to be sent to the client.
    # @param [Integer] statusCode The response status code, optional, default is 500.
    renderError: (res, message, statusCode) =>
        message = JSON.stringify message
        statusCode = 500 if not statusCode?
        res.statusCode = 500
        res.send "Server error: #{message}"
        logger.error "App", "HTTP Error", statusCode, message, res


# Singleton implementation
# --------------------------------------------------------------------------
App.getInstance = ->
    @instance = new App() if not @instance?
    return @instance

module.exports = exports = App.getInstance()