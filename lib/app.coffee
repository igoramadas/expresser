# EXPRESSER APP
# -----------------------------------------------------------------------------
# The Express app server. By default it will run on HTTP port 8080
# <!--
# @see settings.app
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

    # @property [Array<Object>] Array of additional middlewares to be used
    # by the Express server. These will be called before anything is processed,
    # so should be used for things that need immediate processing
    # (firewall, for example).
    prependMiddlewares: []
    
    # @property [Array<Object>] Array of additional middlewares to be used
    # by the Express server. Please note that if you're adding middlewares
    # manually you must do it BEFORE calling `init`.
    appendMiddlewares: []

    # INIT
    # --------------------------------------------------------------------------

    # Init the Express server. Firewall and Sockets modules will be
    # used only if available and enabled on the settings.
    # @param [Object] options App init options. If passed as an array, assume it's the array with extra middlewares.
    # @option options [Array] appendMiddlewares Array with extra middlewares to be loaded.
    init: (options) =>
        if lodash.isArray options
            options = {appendMiddlewares: options}
        else if not options?
            options = {}

        # Load settings and utils.
        settings = require "./settings.coffee"
        utils = require "./utils.coffee"
        nodeEnv = process.env.NODE_ENV

        # Set default error handler.
        @setErrorHandler()

        # Require logger.
        logger = require "./logger.coffee"
        logger.debug "App", "init", options

        # Configure Express server and start server.
        @configureServer options
        @startServer()

    # Log proccess termination to the console. This will force flush any buffered logs to disk.
    # Do not log the exit if running under test environment.
    setErrorHandler: =>
        process.on "exit", (sig) ->
            if nodeEnv? and nodeEnv.indexOf("test") < 0
                console.warn "App", "Terminating Expresser app...", Date(Date.now()), sig
            try
                logger.flushLocal()
            catch ex
                console.warn "App", "Could not flush buffered logs to disk.", ex.message

    # Configure the server. Set views, options, use Express modules, etc.
    configureServer: (options) =>
        midBodyParser = require "body-parser"
        midCookieParser = require "cookie-parser"
        midSession = require "cookie-session"
        midCompression = require "compression"
        midErrorHandler = require "errorhandler"

        # Create express v4 app.
        @server = express()

        settings.updateFromPaaS() if settings.app.paas

        # Set view options, use Jade for HTML templates.
        @server.set "views", settings.path.viewsDir
        @server.set "view engine", settings.app.viewEngine
        @server.set "view options", { layout: false }

        # Check for extra middlewares to be added before any other middlewares.
        if options.prependMiddlewares?
            if lodash.isArray options.prependMiddlewares
                @prependMiddlewares.push mw for mw in options.prependMiddlewares
            else
                @prependMiddlewares.push options.prependMiddlewares

        # Prepend middlewares, if any was specified.
        if @prependMiddlewares.length > 0
            @server.use mw for mw in @prependMiddlewares

        # Enable firewall?
        if settings.firewall?.enabled
            firewall = require "./firewall.coffee"
            firewall.bind @server

        # Use Express basic handlers.
        @server.use midBodyParser.json()
        @server.use midBodyParser.urlencoded {extended: true}
        @server.use midCookieParser settings.app.cookieSecret if settings.app.cookieEnabled
        @server.use midSession {secret: settings.app.sessionSecret} if settings.app.sessionEnabled

        # Use HTTP compression only if enabled on settings.
        @server.use midCompression if settings.app.compressionEnabled

        # Fix connect assets helper context.
        connectAssetsOptions = lodash.cloneDeep settings.app.connectAssets
        connectAssetsOptions.helperContext = @server.locals

        # Connect assets and dynamic compiling.
        ConnectAssets = (require "connect-assets") connectAssetsOptions
        @server.use ConnectAssets

        # Check for extra middlewares to be added.
        if options.appendMiddlewares?
            if lodash.isArray options.appendMiddlewares
                @appendMiddlewares.push mw for mw in options.appendMiddlewares
            else
                @appendMiddlewares.push options.appendMiddlewares

        # Add more middlewares, if any (for example passport for authentication).
        if @appendMiddlewares.length > 0
            @server.use mw for mw in @appendMiddlewares

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
                throw new Error "The certificate files could not be found. Please check the 'Path.sslKeyFile' and 'Path.sslCertFile' settings."
        else
            server = http.createServer @server

        # Enable sockets?
        if settings.sockets.enabled
            sockets = @expresser.sockets
            sockets.bind server

        if settings.app.ip? and settings.app.ip isnt ""
            server.listen settings.app.port, settings.app.ip
            logger.info "App", settings.app.title, "Listening on #{settings.app.ip} - #{settings.app.port}"
        else
            server.listen settings.app.port
            logger.info "App", settings.app.title, "Listening on #{settings.app.port}"

        # Using SSL and redirector port is set? Then create the http server.
        if settings.app.ssl.enabled and settings.app.ssl.redirectorPort > 0
            logger.info "App", "#{settings.app.title} will redirect HTTP #{settings.app.ssl.redirectorPort} to HTTPS on #{settings.app.port}."

            redirServer = express()
            redirServer.get "*", (req, res) -> res.redirect "https://#{req.hostname}:#{settings.app.port}#{req.url}"
            @redirectorServer = http.createServer redirServer
            @redirectorServer.listen settings.app.ssl.redirectorPort

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
        options.title = settings.app.title if not options.title?
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
