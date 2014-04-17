# EXPRESSER APP
# -----------------------------------------------------------------------------
# The Express app server, with built-in sockets, firewall and New Relic integration.
# <!--
# @see Settings.app
# @see Firewall
# @see Sockets
# -->
class App

    express = require "express"
    fs = require "fs"
    http = require "http"
    https = require "https"
    lodash = require "lodash"
    net = require "net"
    path = require "path"

    # Current node environment and HTTP server handler are set on init.
    nodeEnv = null

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

    # INIT
    # --------------------------------------------------------------------------

    # Init the Express server. If New Relic settings are set it will automatically
    # require and use the `newrelic` module. Firewall and Sockets modules will be
    # used only if enabled on the settings.
    # @param [Object] options App init options. If passed as an array, assume it's the array with extra middlewares.
    # @option options [Array] extraMiddlewares Array with extra middlewares to be loaded.
    init: (options) =>
        if lodash.isArray options
            options = {extraMiddlewares: options}
        else if not options?
            options = {}

        # Load settings and utils.
        settings = require "./settings.coffee"
        utils = require "./utils.coffee"
        nodeEnv = process.env.NODE_ENV

        # Init New Relic, if enabled, and set default error handler.
        @initNewRelic()
        @setErrorHandler()

        # Require logger.
        logger = require "./logger.coffee"
        logger.debug "App", "init", options.extraMiddlewares

        # Configure Express server and start server.
        @configureServer options
        @startServer()

    # Init new Relic, depending on its settings (enabled, appName and LicenseKey).
    initNewRelic: =>
        enabled = settings.newRelic.enabled
        appName = process.env.NEW_RELIC_APP_NAME or settings.newRelic.appName
        licKey = process.env.NEW_RELIC_LICENSE_KEY or settings.newRelic.licenseKey

        # Check if New Relic settings are available, and if so, start the New Relic agent.
        if enabled and appName? and appName isnt "" and licKey? and licKey isnt ""
            targetFile = path.resolve path.dirname(require.main.filename), "newrelic.js"

            # Make sure the newrelic.js file exists on the app root, and create one if it doesn't.
            if not fs.existsSync targetFile
                if process.versions.node.indexOf(".10.") > 0
                    enc = {encoding: settings.general.encoding}
                else
                    enc = settings.general.encoding

                # Set values of newrelic.js file and write it to the app root.
                newRelicJson = "exports.config = {app_name: ['#{appName}'], license_key: '#{licKey}', logging: {level: 'trace'}};"
                fs.writeFileSync targetFile, newRelicJson, enc

                console.log "App", "Original newrelic.js file was copied to the app root, app_name and license_key were set."

            require "newrelic"
            console.log "App", "Started New Relic agent for #{appName}."

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
    configureServer: (options) =>
        midBodyParser = require "body-parser"
        midCookieParser = require "cookie-parser"
        midSession = require "express-session"
        midCompression = require "compression"
        midErrorHandler = require "errorhandler"

        # Create express v4 app.
        @server = express()

        settings.updateFromPaaS() if settings.app.paas

        # Set view options, use Jade for HTML templates.
        @server.set "views", settings.path.viewsDir
        @server.set "view engine", settings.app.viewEngine
        @server.set "view options", { layout: false }

        # Enable firewall?
        if settings.firewall.enabled
            firewall = require "./firewall.coffee"
            firewall.init @server

        # Use Express basic handlers.
        @server.use midBodyParser()
        @server.use midCookieParser settings.app.cookieSecret if settings.app.cookieEnabled
        @server.use midSession {secret: settings.app.sessionSecret} if settings.app.sessionEnabled

        # Use HTTP compression only if enabled on settings.
        @server.use midCompression if settings.app.compressionEnabled

        # Fix connect assets helper context.
        connectAssetsOptions = settings.app.connectAssets
        connectAssetsOptions.helperContext = @server.locals

        # Connect assets and dynamic compiling.
        ConnectAssets = (require "connect-assets") connectAssetsOptions
        @server.use ConnectAssets

        # Check for extra middlewares to be added.
        if options.extraMiddlewares?
            if lodash.isArray options.extraMiddlewares
                @extraMiddlewares.push mw for mw in options.extraMiddlewares
            else
                @extraMiddlewares.push options.extraMiddlewares

        # Add more middlewares, if any (for example passport for authentication).
        if @extraMiddlewares.length > 0
            @server.use mw for mw in @extraMiddlewares

        # Configure development environment to dump exceptions and show stack.
        if nodeEnv is "development"
            @server.use midErrorHandler {dumpExceptions: true, showStack: true}

        # Configure production environment.
        if nodeEnv is "production"
            @server.use midErrorHandler()

        # Use Express static routing.
        @server.use express.static settings.path.publicDir

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

    # Start the server using HTTP or HTTPS, depending on the settings.
    startServer: =>
        if settings.app.ssl.enabled and settings.path.sslKeyFile? and settings.path.sslCertFile?
            sslKeyFile = utils.getFilePath settings.path.sslKeyFile
            sslCertFile = utils.getFilePath settings.path.sslCertFile

            # Certificate files were found? Proceed, otherwise alert the user and throw an error.
            if sslKeyFile? and sslCertFile?
                sslKey = fs.readFileSync sslKeyFile, {encoding: settings.general.encoding}
                sslCert = fs.readFileSync sslCertFile, {encoding: settings.general.encoding}
                sslOptions = {key: sslKey, cert: sslCert}
                server = https.createServer sslOptions, @server
            else
                logger.error "App", "init", "Cannot find certificate files.", settings.path.sslKeyFile, settings.path.sslCertFile
                throw new Error "The certificate files could not be found. Please check the 'Path.sslKeyFile' and 'Path.sslCertFile' settings."
        else
            server = http.createServer @server

        # Enable sockets?
        if settings.sockets.enabled
            sockets = require "./sockets.coffee"
            sockets.init server

        # Start the server and log output.
        try
            if settings.app.ip? and settings.app.ip isnt ""
                server.listen settings.app.port, settings.app.ip
                logger.info "App", settings.general.appTitle, "Listening on #{settings.app.ip} - #{settings.app.port}"
            else
                server.listen settings.app.port
                logger.info "App", settings.general.appTitle, "Listening on #{settings.app.port}"
    
            # Using SSL and redirector port is set? Then create the http server.
            if settings.app.ssl.enabled and settings.app.ssl.redirectorPort > 0
                logger.info "App", "#{settings.general.appTitle} will redirect HTTP #{settings.app.ssl.redirectorPort} to HTTPS on #{settings.app.port}."
                redirServer = express()
                redirServer.get "*", (req, res) -> res.redirect "https://#{req.host}:#{settings.app.port}#{req.url}"
                @redirectorServer = http.createServer redirServer
                @redirectorServer.listen settings.app.ssl.redirectorPort
        catch ex
            logger.error "App", "Could not start the server!", ex


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