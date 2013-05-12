# EXPRESSER APP
# -----------------------------------------------------------------------------
# The Express app server.

class App

    # Expose the Express server to external modules.
    server: null


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

        # Require other modules.
        database = require "./database.coffee"
        mail = require "./mail.coffee"
        twitter = require "./twitter.coffee"

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

            # Init the logger and other modules.
            logger.init()
            database.init()
            mail.init()
            twitter.init()

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


# Singleton implementation
# --------------------------------------------------------------------------
App.getInstance = ->
    @instance = new App() if not @instance?
    return @instance

module.exports = exports = App.getInstance()