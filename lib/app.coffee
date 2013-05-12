# EXPRESSER APP
# -----------------------------------------------------------------------------
# The Express app server.

class App

    # Expose the Express server to external code.
    server: null

    # Internal modules will be set on `init`.
    logger = null
    settings = null


    # INIT
    # --------------------------------------------------------------------------

    # Init the Node app.
    init: =>

        # Require OS to gather system info, and the server settigs.
        os = require "os"
        settings = require "./settings.coffee"

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

        # Require the logger module.
        logger = require "./logger.coffee"

        # Log unhandled exceptions. Try using the logger, otherwise log to the console.
        process.on "uncaughtException", (err) ->
            try
                logger.error "Unhandled exception!", err.stack
            catch ex
                console.error "Unhandled exception!", Date(Date.now()), err.stack

        # Log proccess termination to the console.
        process.on "exit", (sig) ->
            console.warn "Terminating Expresser app...", Date(Date.now()), sig

        # Require express and create the app.
        express = require "express"
        @server = express()

        # Make it PaaS friendly. Check for environment variables to override specific settings.
        # If no environment variables are found, the app will use whatever is defined on the
        # settings.coffee file.
        checkCloudEnvironment = ->
            # Check for web (IP and port) variables.
            ip = process.env.OPENSHIFT_INTERNAL_IP
            port = process.env.OPENSHIFT_INTERNAL_PORT
            port = process.env.VCAP_APP_PORT if not port? or port is ""
            settings.Web.ip = ip if ip? and ip isnt ""
            settings.Web.port = port if port? and port isnt ""

            # Check for MongoDB variables.
            vcap = process.env.VCAP_SERVICES
            vcap = JSON.parse vcap if vcap?
            if vcap? and vcap isnt ""
                mongo = vcap["mongodb-1.8"]
                mongo = mongo[0]["credentials"] if mongo?
                if mongo?
                    settings.Database.connString = "mongodb://#{mongo.hostname}:#{mongo.port}/#{mongo.db}"

            # Check for logging variables.
            logentriesToken = process.env.LOGENTRIES_TOKEN
            logglyToken = process.env.LOGGLY_TOKEN
            logglySubdomain = process.env.LOGGLY_SUBDOMAIN
            settings.Log.Logentries.token = logentriesToken if logentriesToken? and logentriesToken isnt ""
            settings.Log.Loggly.token = logglyToken if logglyToken? and logglyToken isnt ""
            settings.Log.Loggly.subdomain = logglySubdomain if logglySubdomain? and logglySubdomain isnt ""

        # General configuration of the app (for all environments).
        @server.configure =>
            checkCloudEnvironment()

            # Set view options, use Jade for HTML templates.
            @server.set "views", settings.Path.viewsDir
            @server.set "view engine", settings.Web.viewEngine
            @server.set "view options", { layout: false }

            # Express settings.
            @server.use express.bodyParser()
            @server.use express.cookieParser settings.Web.cookieSecret
            @server.use express.compress()
            @server.use express.methodOverride()
            @server.use express["static"] settings.Path.publicDir
            @server.use @server.router

            # Connect assets and dynamic compiling.
            ConnectAssets = (require "connect-assets") settings.ConnectAssets
            @server.use ConnectAssets

            # If debug is on, log requests to the console.
            if settings.General.debug
                @server.use (req, res, next) ->
                    console.log "Expresser", "Request", req.method, req.url
                    next()

        # Configure development environment.
        @server.configure "development", =>
            @server.use express.errorHandler settings.ErrorHandling

        # Configure production environment.
        @server.configure "production", =>
            @server.use express.errorHandler()

        # Start the server.
        if settings.Web.ip? and settings.Web.ip isnt ""
            @server.listen settings.Web.ip, settings.Web.port
        else
            @server.listen settings.Web.port

        console.log "Expresser", "App started on port #{settings.Web.port}."


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

    # Get the client / browser IP.
    getClientIP: (req) =>
        try
            xfor = req.header("X-Forwarded-For")
            if xfor? and xfor isnt ""
                ip = xfor.split(",")[0]
            else
                ip = req.connection.remoteAddress
        catch ex
            ip = req.connection.remoteAddress
        return ip


# Singleton implementation
# --------------------------------------------------------------------------
App.getInstance = ->
    @instance = new App() if not @instance?
    return @instance

module.exports = exports = App.getInstance()