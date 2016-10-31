# EXPRESSER APP
# -----------------------------------------------------------------------------
# The Express server. By default it will run on HTTP port 8080
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

    # @property {Object} Exposes the Express HTTP or HTTPS `server` object.
    server: null
    httpServer: null
    httpsServer: null

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
    # @param {Object} options App init options. If passed as an array, assume it's the array with extra middlewares.
    # @option options {Array} appendMiddlewares Array with extra middlewares to be loaded.
    init: (options) =>
        if lodash.isArray options
            options = {appendMiddlewares: options}
        else if not options?
            options = {}

        # Load settings and utils.
        settings = require "./settings.coffee"
        utils = require "./utils.coffee"
        nodeEnv = process.env.NODE_ENV

        # Require logger.
        logger = require "./logger.coffee"
        logger.debug "App", "init", options

        # Configure Express server and start server.
        @configureServer options
        @startServer()

    # Configure the server. Set views, options, use Express modules, etc.
    configureServer: (options) =>
        midBodyParser = require "body-parser"
        midCookieParser = require "cookie-parser"
        midSession = require "cookie-session"
        midCompression = require "compression"

        if nodeEnv is "development" or nodeEnv is "test"
            midErrorHandler = require "errorhandler"

        # Create express v4 app.
        @server = express()

        settings.updateFromPaaS() if settings.app.paas

        # Set view options, use Pug for HTML templates.
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

        # Use Express basic handlers.
        @server.use midBodyParser.json {limit: settings.app.bodyParser.limit}
        @server.use midBodyParser.urlencoded {extended: settings.app.bodyParser.extended, limit: settings.app.bodyParser.limit}
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
        if nodeEnv is "development" or nodeEnv is "test"
            @server.use midErrorHandler {dumpExceptions: true, showStack: true}

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
        if settings.app.ssl.enabled and settings.app.ssl.keyFile? and settings.app.ssl.certFile?
            sslKeyFile = utils.getFilePath settings.app.ssl.keyFile
            sslCertFile = utils.getFilePath settings.app.ssl.certFile

            # Certificate files were found? Proceed, otherwise alert the user and throw an error.
            if sslKeyFile? and sslCertFile?
                if fs.existsSync(sslKeyFile) and fs.existsSync(sslCertFile)
                    sslKey = fs.readFileSync sslKeyFile, {encoding: settings.general.encoding}
                    sslCert = fs.readFileSync sslCertFile, {encoding: settings.general.encoding}
                    sslOptions = {key: sslKey, cert: sslCert}
                    @httpsServer = https.createServer sslOptions, @server
                    serverRef = @httpsServer
                else
                    throw new Error "The certificate files could not be found. Please check the 'settings.app.ssl' settings."
            else
                throw new Error "SSL is enabled but no key and certificate files were defined. Please check the 'settings.app.ssl' settings."
        else
            @httpServer = http.createServer @server
            serverRef = @httpServer

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

            @redirectorServer = http.createServer redirServer
            @redirectorServer.listen settings.app.ssl.redirectorPort

    # HELPER AND UTILS
    # --------------------------------------------------------------------------

    # Helper to render Pug views. The request, response and view are mandatory,
    # and the options argument is optional.
    # @param {Object} req The request object.
    # @param {Object} res The response object.
    # @param {String} view The Pug filename.
    # @param {Object} options Options passed to the view, optional.
    renderView: (req, res, view, options) =>
        options = {} if not options?
        options.device = utils.getClientDevice req
        options.title = settings.app.title if not options.title?

        # View filename must jave .pug extension.
        view += ".pug" if view.indexOf(".pug") < 0

        res.render view, options

        logger.debug "App.renderView", req.originalUrl, view, options

    # Render response as human readable JSON data.
    # @param {Object} req The request object.
    # @param {Object} res The response object.
    # @param {Object} data The JSON data to be sent.
    renderJson: (req, res, data) =>
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

        logger.debug "App.renderJson", req.originalUrl, data

    # Render response as image.
    # @param {Object} req The request object.
    # @param {Object} res The response object.
    # @param {String} filename The full path to the image file.
    # @param {Object} options Options passed to the image renderer, for example the "mimetype".
    renderImage: (req, res, filename, options) ->
        mimetype = options?.mimetype

        # Try to figure out the mime type in case it wasn't passed along the options.
        if not mimetype?
            extname = path.extname(filename).toLowerCase().replace(".","")
            extname = "jpeg" if extname is "jpg"
            mimetype = "image/#{extname}"

        res.contentType mimetype
        res.sendFile filename

        logger.debug "App.renderImage", req.originalUrl, filename, options

    # Send error response as JSON. When the server can't return a valid result,
    # send an error response with the specified status code and error output.
    # @param {Object} req The request object.
    # @param {Object} res The response object.
    # @param {Object} error The error object or message to be sent to the client.
    # @param {Integer} status The response status code, optional, default is 500.
    renderError: (req, res, error, status) =>
        status = 408 if status is "ETIMEDOUT"

        # Set default status to 500 and stringify message if necessary.
        status = status or error?.statusCode or 500
        error = JSON.stringify error if not lodash.isString error

        res.status(status).json {error: error, url: req.originalUrl}

        logger.error "App.renderError", req.originalUrl, status, error

# Singleton implementation
# --------------------------------------------------------------------------
App.getInstance = ->
    @instance = new App() if not @instance?
    return @instance

module.exports = exports = App.getInstance()
