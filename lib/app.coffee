# EXPRESSER APP
# -----------------------------------------------------------------------------
# This is the "core" of an Expresser based application. The App contains
# an Express server, running on HTTP or HTTPs (or both!).
# <!--
# @see settings.app
# -->
class App
    newInstance: -> return new App()

    express = require "express"
    events = require "./events.coffee"
    fs = require "fs"
    http = require "http"
    https = require "https"
    lodash = require "lodash"
    logger = require "./logger.coffee"
    path = require "path"
    settings = require "./settings.coffee"
    utils = require "./utils.coffee"

    # Current node environment and HTTP server handler are set on init.
    nodeEnv = null

    # EXPOSED OBJECTS
    # --------------------------------------------------------------------------

    # @property {Object} Exposes the Express app.
    server: null

    # @property {Object} Exposes the underlying HTTP(s) server(s).
    webServer: null
    redirectorServer: null

    # @property [Array] Additional middlewares to be used by the Express server.
    # These will be called before the default middlewares.
    prependMiddlewares: []

    # @property [Array] Additional middlewares to be used by the Express server.
    # These will be called after the default middlewares.
    appendMiddlewares: []

    # INIT
    # --------------------------------------------------------------------------

    # Create, configure and run the Express server. In most cases this should be
    # the last step of you app loading, after loading custom modules, setting
    # custom configuration, etc.
    init: ->
        logger.debug "App.init"
        events.emit "App.before.init"

        nodeEnv = process.env.NODE_ENV

        # Configure the Express server.
        @configure()

        # Start web server!
        @start()

        events.emit "App.on.init"
        delete @init

    # Configure the server. Set views, options, use Express modules, etc.
    configure: ->
        midBodyParser = require "body-parser"
        midCookieParser = require "cookie-parser"
        midSession = require "cookie-session"
        midCompression = require "compression"

        if nodeEnv is "development" or nodeEnv is "test"
            midErrorHandler = require "errorhandler"

        # Create express v4 app.
        @server = express()

        # Set view options, use Pug for HTML templates.
        @server.set "views", settings.app.viewPath
        @server.set "view engine", settings.app.viewEngine
        @server.set "view options", { layout: false }

        # Prepend middlewares, if any was specified.
        if @prependMiddlewares.length > 0
            @server.use mw for mw in @prependMiddlewares

        # Use Express basic handlers.
        @server.use midBodyParser.json {limit: settings.app.bodyParser.limit}
        @server.use midBodyParser.urlencoded {extended: settings.app.bodyParser.extended, limit: settings.app.bodyParser.limit}

        if settings.app.cookie.enabled
            @server.use midCookieParser settings.app.cookie.secret

        if settings.app.session.enabled
            @server.use midSession {secret: settings.app.session.secret, cookie: {maxAge: new Date(Date.now() + (settings.app.session.maxAge * 1000))}}

        # Use HTTP compression only if enabled on settings.
        if settings.app.compressionEnabled
            @server.use midCompression

        # Fix connect assets helper context.
        connectAssetsOptions = lodash.cloneDeep settings.app.connectAssets
        connectAssetsOptions.helperContext = @server.locals

        # Connect assets and dynamic compiling.
        ConnectAssets = (require "./app/connect-assets.js") connectAssetsOptions
        @server.use ConnectAssets

        # Append extra middlewares, if any was specified.
        if @appendMiddlewares.length > 0
            @server.use mw for mw in @appendMiddlewares

        # Configure development environment to dump exceptions and show stack.
        if nodeEnv is "development" or nodeEnv is "test"
            @server.use midErrorHandler {dumpExceptions: true, showStack: true}

        # Use Express static routing.
        @server.use express.static settings.app.publicPath

        # Log all requests if debug is true.
        if settings.general.debug
            @server.use requestLogger

        # Delete!
        delete @configure

    # START AND KILL
    # --------------------------------------------------------------------------

    # Start the server using HTTP or HTTPS, depending on the settings.
    start: ->
        if @webServer?
            throw new Error "Server is already running on port #{settings.app.port}."

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
                    serverRef = https.createServer sslOptions, @server
                else
                    throw new Error "The certificate files could not be found. Please check the 'settings.app.ssl' settings."
            else
                throw new Error "SSL is enabled but no key and certificate files were defined. Please check the 'settings.app.ssl' settings."
        else
            serverRef = http.createServer @server

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
                redirServer.use requestLogger

            @redirectorServer = http.createServer redirServer
            @redirectorServer.listen settings.app.ssl.redirectorPort

        # Pass the HTTP(s) server created to external modules.
        events.emit "App.on.start", serverRef

    # Kill the underlying HTTP(S) server(s).
    kill: ->
        events.emit "App.before.kill"

        @redirectorServer?.close()
        @redirectorServer = null

        @webServer?.close()
        webServer = null

        events.emit "App.on.kill"

    # HELPER AND UTILS
    # --------------------------------------------------------------------------

    # Return a collection with all routes registered on the server.
    # @param {Boolean} simple If true, returns only an array the route strings.
    # @return {Array} Collection with routes (as object or as string).
    getRoutes: (simple = false) =>
        result = []

        for r in @server._router.stack
            if r.route?.path? and r.route.path isnt ""
                if simple
                    result.push r.route.path
                else
                    result.push {route: r.route.path, methods: lodash.keys(r.route.methods)}

        return result

    # Helper to log all requests when debug is true.
    requestLogger = (req, res, next) ->
        ip = utils.browser.getClientIP req
        method = req.method
        url = req.url

        console.log "Request from #{ip}", method, url

        next() if next?

        return url

    # Helper to render Pug views. The request, response and view are mandatory,
    # and the options argument is optional.
    # @param {Object} req The request object.
    # @param {Object} res The response object.
    # @param {String} view The Pug filename.
    # @param {Object} options Options passed to the view, optional.
    renderView: (req, res, view, options) ->
        logger.debug "App.renderView", req.originalUrl, view, options

        try
            options = {} if not options?
            options.device = utils.browser.getDeviceString req
            options.title = settings.app.title if not options.title?

            # View filename must jave .pug extension.
            view += ".pug" if view.indexOf(".pug") < 0

            # Send rendered view to client.
            res.render view, options

        catch ex
            logger.error "App.renderView", view, ex
            @renderError req, res, ex

        events.emit "App.on.renderView", req, res, view, options

    # Render response as human readable JSON data.
    # @param {Object} req The request object.
    # @param {Object} res The response object.
    # @param {Object} data The JSON data to be sent.
    renderJson: (req, res, data) ->
        logger.debug "App.renderJson", req.originalUrl, data

        if lodash.isString data
            try
                data = JSON.parse data
            catch ex
                return @renderError req, res, ex, 500

        # Remove methods from JSON before rendering.
        cleanJson = (obj) ->
            if lodash.isArray obj
                cleanJson i for i in obj
            else if lodash.isObject obj
                for k, v of obj
                    if lodash.isFunction v
                        delete obj[k]
                    else
                        cleanJson v

        cleanJson data

        # Add Access-Control-Allow-Origin to all when debug is true.
        if settings.general.debug
            res.setHeader "Access-Control-Allow-Origin", "*"

        # Send JSON response.
        res.json data

        events.emit "App.on.renderJson", req, res, data

    # Render response as image.
    # @param {Object} req The request object.
    # @param {Object} res The response object.
    # @param {String} filename The full path to the image file.
    # @param {Object} options Options passed to the image renderer, for example the "mimetype".
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

    # Send error response as JSON. When the server can't return a valid result,
    # send an error response with the specified status code and error output.
    # @param {Object} req The request object.
    # @param {Object} res The response object.
    # @param {Object} error The error object or message to be sent to the client.
    # @param {Integer} status The response status code, optional, default is 500.
    renderError: (req, res, error, status) ->
        logger.error "App.renderError", req.originalUrl, status, error

        status = 408 if status is "ETIMEDOUT"

        # Set default status to 500 and stringify message if necessary.
        status = status or error?.statusCode or 500
        error = error.message + " " + error.stack if lodash.isError error
        error = JSON.stringify error if not lodash.isString error

        # Send error JSON to client.
        res.status(status).json {error: error, url: req.originalUrl}

        events.emit "App.on.renderError", req, res, error, status

# Singleton implementation
# --------------------------------------------------------------------------
App.getInstance = ->
    @instance = new App() if not @instance?
    return @instance

module.exports = exports = App.getInstance()
