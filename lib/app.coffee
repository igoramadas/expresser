# EXPRESSER APP
# -----------------------------------------------------------------------------
# The Express app server.
# Parameters on [settings.html](settings.coffee): Settings.App

class App

    # Expose the Express server to external code, and an array of
    # extra middlewares to be added before the server router.
    server: null
    extraMiddlewares: []

    # Internal modules will be set on `init`.
    firewall = null
    logger = null
    settings = null
    sockets = null
    utils = null


    # INIT
    # --------------------------------------------------------------------------

    # Init the Express server.
    init: =>
        http = require "http"
        os = require "os"
        settings = require "./settings.coffee"
        utils = require "./utils.coffee"

        # Get New Relic environment variables or settings.
        newRelicAppName = process.env.NEW_RELIC_APP_NAME or settings.newRelic.appName
        newRelicLicenseKey = process.env.NEW_RELIC_LICENSE_KEY or settings.newRelic.licenseKey

        # Check if New Relic settings are available, and if so, start the
        # New Relic agent but ONLY if not running under localhost.
        if newRelicAppName? and newRelicAppName isnt "" and newRelicLicenseKey? and newRelicLicenseKey isnt ""
            hostname = os.hostname()
            if hostname is "localhost" or hostname.indexOf(".local") > 0
                console.log "App", "New Relic #{newRelicAppName} won't be embedded because it's running in localhost!", hostname
            else
                console.log "App", "Embeding New Relic agent for #{newRelicAppName}..."
                require "newrelic"

        # Require logger.
        logger = require "./logger.coffee"

        # Log proccess termination to the console. This will force flush any buffered logs to disk.
        process.on "exit", (sig) ->
            console.warn "App", "Terminating Expresser app...", Date(Date.now()), sig

            try
                logger.flushLocal()
            catch err
                console.warn "App", "Could not flush buffered logs to disk."


        # Require express and create the app server.
        express = require "express"
        @server = express()
        httpServer = http.createServer @server

        # General configuration of the app (for all environments).
        @server.configure =>
            utils.updateSettingsFromPaaS() if settings.app.paas

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

            # Connect assets and dynamic compiling.
            ConnectAssets = (require "connect-assets") settings.app.connectAssets
            @server.use ConnectAssets

            # Add more middlewares, if specified (for example passport for authentication).
            if @extraMiddlewares.length > 0
                @server.use mw for mw in @extraMiddlewares

            # Set Express router.
            @server.use @server.router

            # Enable sockets?
            if settings.sockets.enabled
                sockets = require "./sockets.coffee"
                sockets.init httpServer

        # Configure development environment.
        @server.configure "development", =>
            @server.use express.errorHandler {dumpExceptions: true, showStack: true}

        # Configure production environment.
        @server.configure "production", =>
            @server.use express.errorHandler()

        # Start the server.
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
    renderView: (req, res, view, options) =>
        options = {} if not options?
        options.device = utils.getClientDevice req
        options.title = settings.general.appTitle if not options.title?
        res.render view, options
        logger.debug "App", "Render", view, options

    # When the server can't return a valid result, send an error response with the
    # specified status code (default is 500).
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