# EXPRESSER APP
# -----------------------------------------------------------------------------
express = require "express"
errors = require "./errors.coffee"
events = require "./events.coffee"
fs = require "fs"
http = require "http"
https = require "https"
lodash = require "lodash"
logger = require "./logger.coffee"
path = require "path"
settings = require "./settings.coffee"
util = require "util"
utils = require "./utils.coffee"

nodeEnv = null

###
# This is the "core" of an Expresser based application. The App wraps the
# Express server and its middlewares / routes, along with a few extra helpers.
###
class App
    newInstance: -> return new App()

    ##
    # Exposes the Express app object to the outside.
    # @property
    # @type express-Application
    expressApp: null

    ##
    # The underlying HTTP(S) server.
    # @property
    # @type http-Server
    webServer: null

    ##
    # The HTTP to HTTPS redirector server (only if settings.app.ssl.redirectorPort is set).
    # @property
    # @type http-Server
    redirectorServer: null

    ##
    # Additional middlewares to be used by the Express server.
    # These will be called before the default middlewares.
    # @property
    # @type Array
    prependMiddlewares: []

    ##
    # Additional middlewares to be used by the Express server.
    # These will be called after the default middlewares.
    # @property
    # @type Array
    appendMiddlewares: []

    # INIT
    # --------------------------------------------------------------------------

    ###
    # Create, configure and run the Express application. In most cases this should be
    # the last step of you app loading, after loading custom modules, setting custom
    # configuration, etc. Please note that this will be called automatically if
    # you call the main `expresser.init()`.
    ###
    init: ->
        logger.debug "App.init"
        events.emit "App.before.init"

        nodeEnv = process.env.NODE_ENV

        # Get version from main app's package.json (NOT Expresser, but the actual app using it!)
        try
            if @expresser?.rootPath
                @version = require(@expresser.rootPath + "/package.json")?.version
            else
                @version = require(__dirname + "../../package.json")?.version
        catch ex
            logger.error "App.init", "Could not fetch version from package.json.", ex

        # Configure the Express server.
        @configure()

        # Start web server!
        @start()

        events.emit "App.on.init"
        delete @init

    ###
    # Configure the server. Set views, options, use Express modules, etc.
    # Called automatically on `init()`, so normally you should never need
    # to call `configure()` on your own.
    # @private
    ###
    configure: ->
        midBodyParser = require "body-parser"
        midCookieParser = require "cookie-parser"
        midCompression = require "compression"
        midSession = require "express-session"

        if settings.general.debug or nodeEnv is "test"
            midErrorHandler = require "errorhandler"

        # Create express v4 app.
        @expressApp = express()

        # BRAKING! Alert if user is still using old ./views default path for views.
        if not fs.existsSync(settings.app.viewPath)
            logger.warn "Attention!", "Views path not found: #{settings.app.viewPath}", "Note that the default path has changed from ./views/ to ./assets/views/"

        # Set view options, use Pug for HTML templates.
        @expressApp.set "views", settings.app.viewPath
        @expressApp.set "view engine", settings.app.viewEngine
        @expressApp.set "view options", { layout: false }

        # Prepend middlewares, if any was specified.
        if @prependMiddlewares.length > 0
            @expressApp.use mw for mw in @prependMiddlewares

        # Use Express basic handlers.
        @expressApp.use midBodyParser.json {limit: settings.app.bodyParser.limit}
        @expressApp.use midBodyParser.urlencoded {extended: settings.app.bodyParser.extended, limit: settings.app.bodyParser.limit}

        if settings.app.cookie.enabled
            @expressApp.use midCookieParser settings.app.cookie.secret

        if settings.app.session.enabled
            memoryStore = require("memorystore") midSession

            @expressApp.use midSession {
                store: new memoryStore {checkPeriod: settings.app.session.checkPeriod}
                secret: settings.app.session.secret
                resave: false
                saveUninitialized: false
                cookie: {
                    secure: settings.app.session.secure
                    httpOnly: settings.app.session.httpOnly
                    maxAge: new Date(Date.now() + (settings.app.session.maxAge * 1000))
                }
            }

        # Use HTTP compression only if enabled on settings.
        if settings.app.compressionEnabled
            @expressApp.use midCompression

        # Fix connect assets helper context.
        connectAssetsOptions = lodash.cloneDeep settings.app.connectAssets
        connectAssetsOptions.helperContext = @expressApp.locals

        # Connect assets and dynamic compiling.
        ConnectAssets = (require "./app/connect-assets.js") connectAssetsOptions
        @expressApp.use ConnectAssets

        # Append extra middlewares, if any was specified.
        if @appendMiddlewares.length > 0
            @expressApp.use mw for mw in @appendMiddlewares

        # Configure development environment to dump exceptions and show stack.
        if settings.general.debug or nodeEnv is "test"
            @expressApp.use midErrorHandler {dumpExceptions: true, showStack: true}

        # Use Express static routing.
        @expressApp.use express.static settings.app.publicPath

        # Log all requests if debug is true.
        if settings.general.debug
            @expressApp.use (req, res, next) ->
                ip = utils.browser.getClientIP req
                method = req.method
                url = req.url

                console.log "Request from #{ip}", method, url

                next() if next?

                return url

        # We should not call configure more than once!
        delete @configure

    # START AND KILL
    # --------------------------------------------------------------------------

    ###
    # Start the server using HTTP or HTTPS, depending on the settings.
    ###
    start: ->
        if @webServer?
            return logger.warn "App.start", "Application has already started (webServer is not null). Abort!"

        events.emit "App.before.start"

        if settings.app.ssl.enabled and settings.app.ssl.keyFile? and settings.app.ssl.certFile?
            sslKeyFile = utils.io.getFilePath settings.app.ssl.keyFile
            sslCertFile = utils.io.getFilePath settings.app.ssl.certFile

            # Certificate files were found? Proceed, otherwise alert the user and throw an error.
            if sslKeyFile? and sslCertFile?
                if fs.existsSync(sslKeyFile) and fs.existsSync(sslCertFile)
                    sslKey = fs.readFileSync sslKeyFile, {encoding: settings.general.encoding}
                    sslCert = fs.readFileSync sslCertFile, {encoding: settings.general.encoding}
                    sslOptions = {key: sslKey, cert: sslCert}
                    serverRef = https.createServer sslOptions, @expressApp
                else
                    return errors.throw "certificatesNotFound", "Please check paths defined on settings.app.ssl."
            else
                return errors.throw "certificatesNotFound", "Please check paths defined on settings.app.ssl."
        else
            serverRef = http.createServer @expressApp

        # Expose the web server.
        @webServer = serverRef

        # Start the app!
        if settings.app.ip? and settings.app.ip isnt ""
            serverRef.listen settings.app.port, settings.app.ip
            logger.info "App", settings.app.title, "Listening on #{settings.app.ip} port #{settings.app.port}"
        else
            serverRef.listen settings.app.port
            logger.info "App", settings.app.title, "Listening on port #{settings.app.port}"

        # Using SSL and redirector port is set? Then create the http server.
        if settings.app.ssl.enabled and settings.app.ssl.redirectorPort > 0
            logger.info "App", "#{settings.app.title} will redirect HTTP #{settings.app.ssl.redirectorPort} to HTTPS on #{settings.app.port}."

            redirServer = express()
            redirServer.get "*", (req, res) -> res.redirect "https://#{req.hostname}:#{settings.app.port}#{req.url}"

            # Log all redirector requests if debug is true.
            if settings.general.debug
                redirServer.use @requestLogger

            @redirectorServer = http.createServer redirServer
            @redirectorServer.listen settings.app.ssl.redirectorPort

        # Pass the HTTP(s) server created to external modules.
        events.emit "App.on.start", serverRef

    ###
    # Kill the underlying HTTP(S) server(s).
    ###
    kill: ->
        events.emit "App.before.kill"

        try
            @webServer?.close()
            @redirectorServer?.close()
        catch ex
            logger.error "App.kill", ex

        webServer = null
        @redirectorServer = null

        events.emit "App.on.kill"

    # BRIDGED EXPRESS METHODS
    # --------------------------------------------------------------------------

    ##
    # Helper to call the Express App .all().
    all: =>
        return errors.throw "expressNotInit" if not @expressApp?
        logger.debug "App.all", util.inspect(arguments[0]), util.inspect(arguments[1])
        @expressApp.all.apply @expressApp, arguments

    ##
    # Helper to call the Express App .get().
    get: =>
        return errors.throw "expressNotInit" if not @expressApp?
        logger.debug "App.get", util.inspect(arguments[0]), util.inspect(arguments[1])
        @expressApp.get.apply @expressApp, arguments

    ##
    # Helper to call the Express App .post().
    post: =>
        return errors.throw "expressNotInit" if not @expressApp?
        logger.debug "App.post", util.inspect(arguments[0]), util.inspect(arguments[1])
        @expressApp.post.apply @expressApp, arguments

    ##
    # Helper to call the Express App .put().
    put: =>
        return errors.throw "expressNotInit" if not @expressApp?
        logger.debug "App.put", util.inspect(arguments[0]), util.inspect(arguments[1])
        @expressApp.put.apply @expressApp, arguments

    ##
    # Helper to call the Express App .patch().
    patch: =>
        return errors.throw "expressNotInit" if not @expressApp?
        logger.debug "App.patch", util.inspect(arguments[0]), util.inspect(arguments[1])
        @expressApp.patch.apply @expressApp, arguments

    ##
    # Helper to call the Express App .delete().
    delete: =>
        return errors.throw "expressNotInit" if not @expressApp?
        logger.debug "App.delete", util.inspect(arguments[0]), util.inspect(arguments[1])
        @expressApp.delete.apply @expressApp, arguments

    ##
    # Helper to call the Express App .listen().
    listen: =>
        return errors.throw "expressNotInit" if not @expressApp?
        logger.debug "App.listen", util.inspect(arguments[0]), util.inspect(arguments[1])
        @expressApp.listen.apply @expressApp, arguments

    ##
    # Helper to call the Express App .route().
    route: =>
        return errors.throw "expressNotInit" if not @expressApp?
        logger.debug "App.route", arguments[0]
        @expressApp.route.apply @expressApp, arguments

    ##
    # Helper to call the Express App .use().
    use: =>
        return errors.throw "expressNotInit" if not @expressApp?
        logger.debug "App.use", util.inspect(arguments[0]), util.inspect(arguments[1])
        @expressApp.use.apply @expressApp, arguments

    # HELPER AND UTILS
    # --------------------------------------------------------------------------

    ###
    # Return an array with all routes registered on the Express application.
    # @param {Boolean} asString If true, returns the route strings only, otherwise returns full objects.
    # @return {Array} Array with the routes (as object or as string if asString = true).
    ###
    listRoutes: (asString = false) =>
        result = []

        for r in @expressApp._router.stack
            if r.route?.path? and r.route.path isnt ""
                if asString
                    result.push r.route.path
                else
                    result.push {route: r.route.path, methods: lodash.keys(r.route.methods)}

        return result

    ###
    # Render a Pug view and send to the client.
    # @param {Object} req The Express request object, mandatory.
    # @param {Object} res The Express response object, mandatory.
    # @param {String} view The Pug view filename, mandatory.
    # @param {Object} options Options passed to the view, optional.
    ###
    renderView: (req, res, view, options) ->
        logger.debug "App.renderView", req.originalUrl, view, options

        try
            options = {} if not options?
            options.device = utils.browser.getDeviceDetails req
            options.title = settings.app.title if not options.title?

            # View filename must jave .pug extension.
            view += ".pug" if view.indexOf(".pug") < 0

            # Send rendered view to client.
            res.render view, options

        catch ex
            logger.error "App.renderView", view, ex
            @renderError req, res, ex

        events.emit "App.on.renderView", req, res, view, options

    ###
    # Render response as JSON data and send to the client.
    # @param {Object} req The Express request object, mandatory.
    # @param {Object} res The Express response object, mandatory.
    # @param {Object} data The JSON data to be sent, mandatory.
    ###
    renderJson: (req, res, data) ->
        logger.debug "App.renderJson", req.originalUrl, data

        if lodash.isString data
            try
                data = JSON.parse data
            catch ex
                return @renderError req, res, ex, 500

        # Remove methods from JSON before rendering.
        cleanJson = (obj, depth) ->
            if depth > settings.logger.maxDepth
                return

            if lodash.isArray obj
                for i in obj
                    cleanJson i, depth + 1
            else if lodash.isObject obj
                for k, v of obj
                    if lodash.isFunction v
                        delete obj[k]
                    else
                        cleanJson v, depth + 1

        cleanJson data, 0

        # Add Access-Control-Allow-Origin to all when debug is true.
        if settings.general.debug
            res.setHeader "Access-Control-Allow-Origin", "*"

        # Send JSON response.
        res.json data

        events.emit "App.on.renderJson", req, res, data

    ###
    # Render an image from the speficied file, and send to the client.
    # @param {Object} req The Express request object, mandatory.
    # @param {Object} res The Express response object, mandatory.
    # @param {String} filename The full path to the image file, mandatory.
    # @param {Object} options Options passed to the image renderer, for example the "mimetype".
    ###
    renderImage: (req, res, filename, options) ->
        logger.debug "App.renderImage", req.originalUrl, filename, options

        mimetype = options?.mimetype

        # Try to figure out the mime type in case it wasn't passed along the options.
        if not mimetype?
            extname = path.extname(filename).toLowerCase().replace(".","")
            extname = "jpeg" if extname is "jpg"
            mimetype = "image/#{extname}"

        # Send image to client.
        res.contentType mimetype
        res.sendFile filename

        events.emit "App.on.renderImage", req, res, filename, options

    ###
    # Sends error response as JSON.
    # @param {Object} req The Express request object, mandatory.
    # @param {Object} res The Express response object, mandatory.
    # @param {Object} error The error object or message to be sent to the client, mandatory.
    # @param {Number} status The response status code, optional, default is 500.
    ###
    renderError: (req, res, error, status) ->
        logger.debug "App.renderError", req.originalUrl, status, error

        # Status defaults to 500.
        status = error?.statusCode or 500 if not status?
        status = 408 if status is "ETIMEDOUT"

        # Helper to build message out of the error object.
        getMessage = (obj) ->
            msg = {}

            if lodash.isString obj
                msg.message = obj
            else
                msg.message = obj.message if obj.message?
                msg.friendlyMessage = obj.friendlyMessage if obj.friendlyMessage?
                msg.reason = obj.reason if obj.reason?
                msg.code = obj.code if obj.code?

            # Nothing taken out of error objec? Return null then.
            if lodash.keys(msg).length is 0
                return null

            return msg

        try
            message = getMessage error

            # Error might be encapsulated inside another "error" property.
            if not mesage? and error.error?
                message = getMessage error.error

        catch ex
            logger.error "App.renderError", ex

        # Can't figure it out? Just pass error as string then.
        if not message?
            message = error.toString()

        # Send error JSON to client.
        res.status(status).json {error: message, url: req.originalUrl}

        events.emit "App.on.renderError", req, res, error, status

# Singleton implementation
# -----------------------------------------------------------------------------
App.getInstance = ->
    @instance = new App() if not @instance?
    return @instance

module.exports = App.getInstance()
