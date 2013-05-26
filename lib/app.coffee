# EXPRESSER APP
# -----------------------------------------------------------------------------
# The Express app server.
# Parameters on settings.coffee: Settings.App

class App

    # Expose the Express server to external code.
    server: null

    # Internal modules will be set on `init`.
    firewall = null
    logger = null
    settings = null
    sockets = null
    utils = null


    # INIT
    # --------------------------------------------------------------------------

    # Init the Node app.
    init: =>

        # Require OS to gather system info, and the server settigs.
        os = require "os"
        settings = require "./settings.coffee"
        utils = require "./utils.coffee"

        # Get New Relic environment variables.
        newRelicAppName = process.env.NEW_RELIC_APP_NAME or settings.NewRelic.appName
        newRelicLicenseKey = process.env.NEW_RELIC_LICENSE_KEY or settings.NewRelic.licenseKey

        # Check if New Relic settings are available, and if so, start the
        # New Relic agent but ONLY if not running under localhost.
        if newRelicAppName? and newRelicAppName isnt "" and newRelicLicenseKey? and newRelicLicenseKey isnt ""
            hostname = os.hostname()
            if hostname is "localhost" or hostname.indexOf(".local") > 0
                console.log "Expresser", "New Relic #{newRelicAppName} won't be embedded because it's running in localhost!", hostname
            else
                console.log "Expresser", "Embeding New Relic agent for #{newRelicAppName}..."
                require "newrelic"

        # Require logger.
        logger = require "./logger.coffee"

        # Check if uncaught exceptions should be logged. If so, try logging unhandled
        # exceptions using the logger, otherwise log to the console.
        if settings.Logger.uncaughtException
            process.on "uncaughtException", (err) ->
                try
                    logger.error "Expresser", "Unhandled exception!", err.stack
                catch ex
                    console.error "Expresser", "Unhandled exception!", Date(Date.now()), err.stack

        # Log proccess termination to the console.
        process.on "exit", (sig) ->
            console.warn "Terminating Expresser app...", Date(Date.now()), sig

        # Require express and create the app.
        express = require "express"
        @server = express()

        # General configuration of the app (for all environments).
        @server.configure =>
            utils.updateSettingsFromPaaS() if settings.App.paas

            # Set view options, use Jade for HTML templates.
            @server.set "views", settings.Path.viewsDir
            @server.set "view engine", settings.App.viewEngine
            @server.set "view options", { layout: false }

            # If debug is on, log requests to the console.
            if settings.General.debug
                @server.use (req, res, next) =>
                    ip = utils.getClientIP req
                    method = req.method
                    url = req.url
                    console.log "Expresser", "Request from #{ip}", method, url
                    next() if next?

            # Enable firewall?
            if settings.Firewall.enabled
                firewall = require "./firewall.coffee"
                firewall.init @server

            # Use Express handlers.
            @server.use express.bodyParser()
            @server.use express.cookieParser settings.App.cookieSecret
            @server.use express.compress()
            @server.use express.methodOverride()
            @server.use express["static"] settings.Path.publicDir
            @server.use @server.router

            # Connect assets and dynamic compiling.
            ConnectAssets = (require "connect-assets") settings.ConnectAssets
            @server.use ConnectAssets

            # Enable sockets?
            if settings.Sockets.enabled
                sockets = require "./sockets.coffee"
                sockets.init @server

        # Configure development environment.
        @server.configure "development", =>
            @server.use express.errorHandler settings.ErrorHandling

        # Configure production environment.
        @server.configure "production", =>
            @server.use express.errorHandler()

        # Start the server.
        if settings.App.ip? and settings.App.ip isnt ""
            @server.listen settings.App.ip, settings.App.port
            console.log "Expresser", "App #{settings.General.appTitle} started!", settings.App.ip, settings.App.port
        else
            @server.listen settings.App.port
            console.log "Expresser", "App #{settings.General.appTitle} started!", settings.App.port


    # HELPER AND UTILS
    # --------------------------------------------------------------------------

    # Helper to render pages. The request, response and view are mandatory,
    # and the options argument is optional.
    renderView: (req, res, view, options) =>
        options = {} if not options?
        options.device = @getClientDevice req
        options.title = settings.General.appTitle if not options.title?
        res.render view, options

    # When the server can't return a valid result, send an error response with status code 500.
    renderError: (res, message) =>
        message = JSON.stringify message
        res.statusCode = 500
        res.send "Server error: #{message}"
        logger.error "HTTP Error", message, res

    # Get the client's device identifier string based on the user agent.
    getClientDevice: (req) =>
        ua = req.headers["user-agent"]

        # Find desktop browsers.
        return "chrome" if ua.indexOf("Chrome/") > 0
        return "firefox" if ua.indexOf("Firefox/") > 0
        return "safari" if ua.indexOf("Safari/") > 0
        return "ie-11" if ua.indexOf("MSIE 11") > 0
        return "ie-10" if ua.indexOf("MSIE 10") > 0
        return "ie-9" if ua.indexOf("MSIE 9") > 0
        return "ie" if ua.indexOf("MSIE") > 0

        # Find mobile devices.
        return "wp-8" if ua.indexOf("Windows Phone 8") > 0
        return "wp-7" if ua.indexOf("Windows Phone 7") > 0
        return "wp" if ua.indexOf("Windows Phone") > 0
        return "iphone-5" if ua.indexOf("iPhone5") > 0
        return "iphone-4" if ua.indexOf("iPhone4") > 0
        return "iphone" if ua.indexOf("iPhone") > 0
        return "android-5" if ua.indexOf("Android 5") > 0
        return "android-4" if ua.indexOf("Android 4") > 0
        return "android" if ua.indexOf("Android") > 0

        # Return default desktop value if no specific devices were found on user agent.
        return "desktop"


# Singleton implementation
# --------------------------------------------------------------------------
App.getInstance = ->
    @instance = new App() if not @instance?
    return @instance

module.exports = exports = App.getInstance()