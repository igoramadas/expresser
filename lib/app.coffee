# EXPRESSER APP
# -----------------------------------------------------------------------------
# The Express app server.
# Parameters on [settings.html](settings.coffee): Settings.App

class App

    # Expose the Express server to external code.
    server: null

    # Expose the Passport module to external code. The `passportCallback` must be set by your application
    # with the signature (username, password, callback) for Basic HTTP, or (profile, callback) for LDAP.
    # The `callback` has the signature (err, result).
    passport: null
    passportAuthenticate: null

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

        # Require OS to gather system info, and the server settigs.
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
                console.log "Expresser", "New Relic #{newRelicAppName} won't be embedded because it's running in localhost!", hostname
            else
                console.log "Expresser", "Embeding New Relic agent for #{newRelicAppName}..."
                require "newrelic"

        # Require logger.
        logger = require "./logger.coffee"

        # Check if uncaught exceptions should be logged. If so, try logging unhandled
        # exceptions using the logger, otherwise log to the console.
        if settings.logger.uncaughtException
            process.on "uncaughtException", (err) ->
                try
                    logger.error "Expresser", "Unhandled exception!", err.stack
                catch ex
                    console.error "Expresser", "Unhandled exception!", Date(Date.now()), err.stack, ex

        # Log proccess termination to the console. This will force flush any buffered logs to disk.
        process.on "exit", (sig) ->
            console.warn "Expresser", "Terminating Expresser app...", Date(Date.now()), sig

            try
                logger.flushLocal()
            catch err
                console.warn "Expresser", "Could not flush buffered logs to disk."


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
                    console.log "Expresser", "Request from #{ip}", method, url
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

            # Use passport?
            if settings.passport.enabled
                @passport = require "passport"

                # Enable basic HTTP authentication?
                if settings.passport.basic.enabled
                    @passport.use new (require "passport-http").BasicStrategy (username, password, callback) =>
                        if not @passportAuthenticate?
                            logger.warn "Expresser", "App.passportAuthenticate not set.", "Abort basic HTTP authentication."
                        else
                            @passportAuthenticate username, password, callback

                    if settings.general.debug
                        logger.info "Expresser", "App.configure", "Passport: using basic HTTP authentication."

                # Enable LDAP authentication?
                if settings.passport.ldap.enabled
                    ldapOptions =
                        server: {url: settings.passport.ldap.server}
                        base: settings.passport.ldap.base
                        search: {filter: settings.passport.ldap.filter}

                    @passport.use new (require "passport-ldap").LDAPStrategy ldapOptions, (profile, callback) =>
                        if not @passportAuthenticate?
                            logger.warn "Expresser", "App.passportAuthenticate not set.", "Abort LDAP authentication."
                        else
                            @passportAuthenticate profile, callback

                    if settings.general.debug
                        logger.info "Expresser", "App.configure", "Passport: using LDAP authentication."

                # Init passport.
                @server.use @passport.initialize()
                @server.use @passport.session()

            # Set Express router.
            @server.use @server.router

            # Enable sockets?
            if settings.sockets.enabled
                sockets = require "./sockets.coffee"
                sockets.init httpServer

        # Configure development environment.
        @server.configure "development", =>
            @server.use express.errorHandler {dumpExceptions: false, showStack: false}

        # Configure production environment.
        @server.configure "production", =>
            @server.use express.errorHandler()

        # Start the server.
        if settings.app.ip? and settings.app.ip isnt ""
            httpServer.listen settings.app.ip, settings.app.port
            logger.info "Expresser", "App #{settings.general.appTitle} started!", settings.app.ip, settings.app.port
        else
            httpServer.listen settings.app.port
            logger.info "Expresser", "App #{settings.general.appTitle} started!", settings.app.port


    # HELPER AND UTILS
    # --------------------------------------------------------------------------

    # Helper to render pages. The request, response and view are mandatory,
    # and the options argument is optional.
    renderView: (req, res, view, options) =>
        options = {} if not options?
        options.device = utils.getClientDevice req
        options.title = settings.general.appTitle if not options.title?
        res.render view, options

    # When the server can't return a valid result, send an error response with status code 500.
    renderError: (res, message) =>
        message = JSON.stringify message
        res.statusCode = 500
        res.send "Server error: #{message}"
        logger.error "HTTP Error", message, res




# Singleton implementation
# --------------------------------------------------------------------------
App.getInstance = ->
    @instance = new App() if not @instance?
    return @instance

module.exports = exports = App.getInstance()