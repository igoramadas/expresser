// Expresser: app.ts

import {Http2SecureServer, Http2Server} from "http2"
import {isArray, isFunction, isObject, isString} from "./utils"
import EventEmitter = require("eventemitter3")
import express = require("express")
import fs = require("fs")
import http = require("http")
import https = require("https")
import jaul = require("jaul")
import logger = require("anyhow")
import path = require("path")
import setmeup = require("setmeup")
let settings

/** Middleware definitions to be be passed on app [[init]]. */
export interface MiddlewareDefs {
    /** Single or array of middlewares to be prepended. */
    prepend: any | any[]
    /** Single or array of middlewares to be appended. */
    append: any | any[]
}

/** Main App class. */
export class App {
    private static _instance: App
    /** @hidden */
    static get Instance() {
        return this._instance || (this._instance = new this())
    }

    /** Returns a new fresh instance of the App module. */
    newInstance(): App {
        return new App()
    }

    /** Default App constructor. */
    constructor() {
        if (!logger.isReady) {
            /* istanbul ignore next */
            logger.setup()
        }

        // Load default settings.
        setmeup.load(__dirname + "/../settings.default.json", {overwrite: false})

        settings = setmeup.settings
    }

    // PROPERTIES
    // --------------------------------------------------------------------------

    /** Express application. */
    expressApp: express.Application

    /** The underlying HTTP(S) server. */
    server: any

    /** Event emitter. */
    events: EventEmitter = new EventEmitter()

    // EVENTS
    // --------------------------------------------------------------------------

    /**
     * Bind callback to event. Shortcut to `events.on()`.
     * @param eventName The name of the event.
     * @param callback Callback function.
     */
    on = (eventName: string, callback: EventEmitter.ListenerFn): void => {
        this.events.on(eventName, callback)
    }

    /**
     * Bind callback to event that will be triggered only once. Shortcut to `events.once()`.
     * @param eventName The name of the event.
     * @param callback Callback function.
     */
    once = (eventName: string, callback: EventEmitter.ListenerFn): void => {
        this.events.on(eventName, callback)
    }

    /**
     * Unbind callback from event. Shortcut to `events.off()`.
     * @param eventName The name of the event.
     * @param callback Callback function.
     */
    off = (eventName: string, callback: EventEmitter.ListenerFn): void => {
        this.events.off(eventName, callback)
    }

    // MAIN METHODS
    // --------------------------------------------------------------------------

    /**
     * Init the app module and start the HTTP(S) server.
     * @param middlewares List of middlewares to be appended / prepended.
     * @event init
     */
    init = (middlewares?: MiddlewareDefs): void => {
        let mw

        // Debug enabled?
        if (settings.general.debug && logger.options.levels.indexOf("debug") < 0) {
            logger.setOptions({
                levels: logger.options.levels.concat(["debug"]),
                preprocessorOptions: {
                    errorStack: true
                }
            })
        }

        logger.setOptions({preprocessors: ["cleanup", "friendlyErrors", "maskSecrets"]})

        // Create express v4 app.
        this.expressApp = express()

        middlewares = middlewares || {append: [], prepend: []}

        // Make sure passed middlewares are array based.
        if (middlewares.prepend && !isArray(middlewares.prepend)) {
            middlewares.prepend = [middlewares.prepend]
        }
        if (middlewares.append && !isArray(middlewares.append)) {
            middlewares.append = [middlewares.append]
        }

        // Prepend middlewares?
        if (middlewares.prepend && middlewares.prepend.length > 0) {
            for (mw of middlewares.prepend) {
                if (mw) {
                    this.expressApp.use(mw)
                    logger.debug("App.init", "Prepended middleware")
                }
            }
        }

        // Trust proxy (mainly for secure cookies)?
        this.expressApp.set("trust proxy", settings.app.trustProxy)

        // Default view path.
        this.expressApp.set("views", settings.app.viewPath)

        // Set view options, use Pug for HTML templates.
        if (settings.app.viewEngine) {
            this.expressApp.set("view engine", settings.app.viewEngine)
            this.expressApp.set("view options", settings.app.viewOptions)
        }

        // Use body parser?
        if (settings.app.bodyParser && settings.app.bodyParser.enabled) {
            try {
                const midBodyParser = require("body-parser")
                if (settings.app.bodyParser.rawTypes) {
                    this.expressApp.use(midBodyParser.raw({limit: settings.app.bodyParser.rawLimit, type: settings.app.bodyParser.rawTypes}))
                }
                this.expressApp.use(midBodyParser.json({limit: settings.app.bodyParser.limit}))
                this.expressApp.use(midBodyParser.text({limit: settings.app.bodyParser.limit}))
                this.expressApp.use(midBodyParser.urlencoded({limit: settings.app.bodyParser.limit, extended: settings.app.bodyParser.extended}))
            } catch (ex) {
                /* istanbul ignore next */
                logger.warn("App.init", "Can't load 'body-parser' module.")
            }
        }

        // Cookies enabled? Depends on `cookie-parser` being installed.
        if (settings.app.cookie && settings.app.cookie.enabled) {
            try {
                const midCookieParser = require("cookie-parser")
                this.expressApp.use(midCookieParser(settings.app.secret))
            } catch (ex) {
                /* istanbul ignore next */
                ex.friendlyMessage = "Can't load 'cookie-parser' module."
                /* istanbul ignore next */
                logger.error("App.init", ex)
            }
        }

        // Session enabled?
        if (settings.app.session && settings.app.session.enabled) {
            try {
                const midSession = require("express-session")
                const memoryStore = require("memorystore")(midSession)

                this.expressApp.use(
                    midSession({
                        store: new memoryStore({checkPeriod: settings.app.session.checkPeriod}),
                        proxy: settings.app.session.proxy,
                        resave: settings.app.session.resave,
                        saveUninitialized: settings.app.session.saveUninitialized,
                        secret: settings.app.secret,
                        ttl: settings.app.session.maxAge * 1000,
                        cookie: {
                            secure: settings.app.session.secure,
                            httpOnly: settings.app.session.httpOnly,
                            maxAge: settings.app.session.maxAge * 1000
                        }
                    })
                )
            } catch (ex) {
                /* istanbul ignore next */
                ex.friendlyMessage = "Can't load 'express-session' and 'memorystore' modules."
                /* istanbul ignore next */
                logger.error("App.init", ex)
            }
        }

        // Use HTTP compression only if enabled on settings.
        if (settings.app.compression && settings.app.compression.enabled) {
            try {
                const midCompression = require("compression")
                this.expressApp.use(midCompression())
            } catch (ex) {
                /* istanbul ignore next */
                ex.friendlyMessage = "Can't load 'compression' module."
                /* istanbul ignore next */
                logger.error("App.init", ex)
            }
        }

        // Use Express static routing.
        if (settings.app.publicPath) {
            this.expressApp.use(express.static(settings.app.publicPath))
        }

        // Append middlewares?
        if (middlewares.append && middlewares.append.length > 0) {
            for (mw of middlewares.append) {
                if (mw) {
                    this.expressApp.use(mw)
                    logger.debug("App.init", "Appended middleware")
                }
            }
        }

        // Log all requests if debug is true.
        if (settings.general.debug) {
            this.expressApp.use(function (req, res, next) {
                const {method} = req
                const {url} = req
                const ip = jaul.network.getClientIP(req)
                const msg = `Request from ${ip}`

                if (res) {
                    logger.debug("App", msg, method, url)
                }

                if (next) {
                    next()
                }

                return url
            })
        }

        // Disable the X-Powered-By header.
        this.expressApp.disable("x-powered-by")

        // Dispatch init event, and start the server.
        this.events.emit("init")
        this.start()
    }

    /**
     * Start the HTTP(S) server.
     * @returns The HTTP(S) server created by Express.
     * @event start
     */
    start = (): Http2Server | Http2SecureServer => {
        if (this.server) {
            logger.warn("App.start", "Server is already running, abort start.")
            return this.server
        }

        let serverRef

        if (settings.app.ssl && settings.app.ssl.enabled && settings.app.ssl.keyFile && settings.app.ssl.certFile) {
            const sslKeyFile = jaul.io.getFilePath(settings.app.ssl.keyFile)
            const sslCertFile = jaul.io.getFilePath(settings.app.ssl.certFile)

            // Certificate files were found? Proceed, otherwise alert the user and throw an error.
            if (sslKeyFile && sslCertFile) {
                const sslKey = fs.readFileSync(sslKeyFile, {encoding: settings.general.encoding})
                const sslCert = fs.readFileSync(sslCertFile, {encoding: settings.general.encoding})
                const sslOptions = {key: sslKey, cert: sslCert}
                serverRef = https.createServer(sslOptions, this.expressApp)
            } else {
                throw new Error("Invalid certificate filename, please check paths defined on settings.app.ssl.")
            }
        } else {
            serverRef = http.createServer(this.expressApp)
        }

        // Expose the web server.
        this.server = serverRef

        let listenCb = () => {
            if (settings.app.ip) {
                logger.info("App.start", settings.app.title, `Listening on ${settings.app.ip} port ${settings.app.port}`, `URL ${settings.app.url}`)
            } else {
                logger.info("App.start", settings.app.title, `Listening on port ${settings.app.port}`, `URL ${settings.app.url}`)
            }
        }

        /* istanbul ignore next */
        let listenError = (err) => {
            /* istanbul ignore next */
            logger.error("App.start", "Can't start", err)
        }

        // Start the app!
        if (settings.app.ip) {
            serverRef.listen(settings.app.port, settings.app.ip, listenCb).on("error", listenError)
        } else {
            serverRef.listen(settings.app.port, listenCb).on("error", listenError)
        }

        // Set default timeout.
        serverRef.timeout = settings.app.timeout

        // Emit start event and return HTTP(S) server.
        this.events.emit("start")
        return this.server
    }

    /**
     * Kill the underlying HTTP(S) server(s).
     * @event kill
     */
    kill = (): void => {
        if (!this.server) {
            logger.warn("App.kill", "Server was not running")
            return
        }

        try {
            this.server.close()
            this.server = null
            this.events.emit("kill")
        } catch (ex) {
            /* istanbul ignore next */
            logger.error("App.kill", ex)
        }
    }

    // BRIDGED METHODS
    // --------------------------------------------------------------------------

    /**
     * Shortcut to express ".all()".
     * @param args Arguments passed to Express.
     */
    all = (...args: any[]) => {
        logger.debug("App.all", args[1], args[2])
        return this.expressApp.all.apply(this.expressApp, args)
    }

    /**
     * Shortcut to express ".get()".
     * @param args Arguments passed to Express.
     */
    get = (...args: any[]) => {
        logger.debug("App.get", args[1], args[2])
        return this.expressApp.get.apply(this.expressApp, args)
    }

    /**
     * Shortcut to express ".post()".
     * @param args Arguments passed to Express.
     */
    post = (...args: any[]) => {
        logger.debug("App.post", args[1], args[2])
        return this.expressApp.post.apply(this.expressApp, args)
    }

    /**
     * Shortcut to express ".put()".
     * @param args Arguments passed to Express.
     */
    put = (...args: any[]) => {
        logger.debug("App.put", args[1], args[2])
        return this.expressApp.put.apply(this.expressApp, args)
    }

    /**
     * Shortcut to express ".patch()".
     * @param args Arguments passed to Express.
     */
    patch = (...args: any[]) => {
        logger.debug("App.patch", args[1], args[2])
        return this.expressApp.patch.apply(this.expressApp, args)
    }

    /**
     * Shortcut to express ".delete()".
     * @param args Arguments passed to Express.
     */
    delete = (...args: any[]) => {
        logger.debug("App.delete", args[1], args[2])
        return this.expressApp.delete.apply(this.expressApp, args)
    }

    /**
     * Shortcut to express ".head()".
     * @param args Arguments passed to Express.
     */
    head = (...args: any[]) => {
        logger.debug("App.head", args[1], args[2])
        return this.expressApp.head.apply(this.expressApp, args)
    }

    /**
     * Shortcut to express ".use()".
     * @param args Arguments passed to Express.
     */
    use = (...args: any[]) => {
        logger.debug("App.use", args[1], args[2])
        return this.expressApp.use.apply(this.expressApp, args)
    }

    /**
     * Shortcut to express ".set()".
     * @param args Arguments passed to Express.
     */
    set = (...args: any[]) => {
        logger.debug("App.set", args[1], args[2])
        return this.expressApp.set.apply(this.expressApp, args)
    }

    /**
     * Shortcut to express ".route()".
     * @param reqPath The path of the desired route.
     * @returns An instance of a single route for the specified path.
     */
    route = (reqPath: string): express.IRoute => {
        logger.debug("App.route", reqPath)
        return this.expressApp.route.apply(this.expressApp, reqPath)
    }

    // RENDERING METHODS
    // --------------------------------------------------------------------------

    /**
     * Render a view and send to the client. The view engine depends on the settings defined.
     * @param req The Express request object.
     * @param res The Express response object.
     * @param view The view filename.
     * @param options Options passed to the view, optional.
     * @param status Optional status code, defaults to 200.
     * @event renderView
     */
    renderView = (req: express.Request, res: express.Response, view: string, options?: any, status?: number) => {
        logger.debug("App.renderView", req.originalUrl, view, options)

        try {
            if (!options) {
                options = {}
            }

            if (options.title == null) {
                options.title = settings.app.title
            }

            // A specific status code was passed?
            if (status) {
                res.status(status)
            }

            // Send rendered view to client.
            res.render(view, options)
        } catch (ex) {
            /* istanbul ignore next */
            logger.error("App.renderView", view, ex)
            /* istanbul ignore next */
            this.renderError(req, res, ex)
        }

        /* istanbul ignore if */
        if (settings.app.events.render) {
            this.events.emit("renderView", req, res, view, options, status)
        }
    }

    /**
     * Sends pure text to the client.
     * @param req The Express request object.
     * @param res The Express response object.
     * @param text The text to be rendered, mandatory.
     * @param status Optional status code, defaults to 200.
     * @event renderText
     */
    renderText = (req: express.Request, res: express.Response, text: any, status?: number) => {
        logger.debug("App.renderText", req.originalUrl, text)

        try {
            if (text == null) {
                logger.debug("App.renderText", "Called with empty text parameter")
                text = ""
            } else if (!isString(text)) {
                text = text.toString()
            }

            // A specific status code was passed?
            if (status) {
                res.status(status)
            }

            res.setHeader("content-type", "text/plain")
            res.send(text)
        } catch (ex) {
            /* istanbul ignore next */
            logger.error("App.renderText", text, ex)
            /* istanbul ignore next */
            this.renderError(req, res, ex)
        }

        /* istanbul ignore if */
        if (settings.app.events.render) {
            this.events.emit("renderText", req, res, text, status)
        }
    }

    /**
     * Render response as JSON data and send to the client.
     * @param req The Express request object.
     * @param res The Express response object.
     * @param data The JSON data to be sent.
     * @param status Optional status code, defaults to 200.
     * @event renderJson
     */
    renderJson = (req: express.Request, res: express.Response, data: any, status?: number) => {
        logger.debug("App.renderJson", req.originalUrl, data)

        if (isString(data)) {
            try {
                data = JSON.parse(data)
            } catch (ex) {
                logger.error("App.renderJson", ex)
                return this.renderError(req, res, ex, 500)
            }
        }

        // Remove methods from JSON before rendering.
        var cleanJson = function (obj, depth) {
            if (depth >= settings.logger.maxDepth) {
                return
            }

            if (isArray(obj)) {
                return Array.from(obj).map((i) => cleanJson(i, depth + 1))
            } else if (isObject(obj)) {
                return (() => {
                    const result = []
                    for (let k in obj) {
                        const v = obj[k]
                        if (isFunction(v)) {
                            result.push(delete obj[k])
                        } else {
                            result.push(cleanJson(v, depth + 1))
                        }
                    }
                    return result
                })()
            }
        }

        cleanJson(data, 0)

        // A specific status code was passed?
        if (status) {
            res.status(status)
        }

        // Add Access-Control-Allow-Origin if set.
        if (settings.app.allowOriginHeader) {
            res.setHeader("Access-Control-Allow-Origin", settings.app.allowOriginHeader)
        }

        // Send JSON response.
        res.json(data)

        /* istanbul ignore if */
        if (settings.app.events.render) {
            this.events.emit("renderJson", req, res, data, status)
        }
    }

    /**
     * Render an image from the speficied file, and send to the client.
     * @param req The Express request object.
     * @param res The Express response object.
     * @param filename The full path to the image file.
     * @param options Options passed to the image renderer, for example the "mimetype".
     * @event renderImage
     */
    renderImage = (req: express.Request, res: express.Response, filename: string, options?: any) => {
        logger.debug("App.renderImage", req.originalUrl, filename, options)

        let mimetype = options ? options.mimetype : null

        // Try to figure out the mime type in case it wasn't passed along the options.
        if (!mimetype) {
            let extname = path.extname(filename).toLowerCase().replace(".", "")

            if (extname == "jpg") {
                extname = "jpeg"
            }

            mimetype = `image/${extname}`
        }

        // Send image to client.
        res.type(mimetype)
        res.sendFile(filename)

        /* istanbul ignore if */
        if (settings.app.events.render) {
            this.events.emit("renderImage", req, res, filename, options)
        }
    }

    /**
     * Sends error response as JSON.
     * @param req The Express request object.
     * @param res The Express response object.
     * @param error The error object or message to be sent to the client.
     * @param status The response status code, optional, default is 500.
     * @event renderError
     */
    renderError = (req: express.Request, res: express.Response, error: any, status?: number | string) => {
        let message
        logger.debug("App.renderError", req.originalUrl, status, error)

        /* istanbul ignore next */
        if (typeof error == "undefined" || error == null) {
            error = "Unknown error"
            logger.warn("App.renderError", "Called with null error")
        }

        // Status default statuses.
        if (status == null) {
            status = error.statusCode || error.status || error.code
        }
        if (status == "ETIMEDOUT") {
            status = 408
        }

        // Error defaults to 500 if not a valid number.
        if (isNaN(status as number)) {
            status = 500
        } else {
            status = parseInt(status as string)
        }

        try {
            // Error inside another .error property?
            if (error.error && !error.message && !error.error_description && !error.reason) {
                error = error.error
            }

            if (isString(error)) {
                message = {message: error}
            } else {
                message = {}
                message.message = error.message || error.error_description || error.description

                // No message found? Just use the default .toString() then.
                /* istanbul ignore next */
                if (!message.message) {
                    message.message = error.toString()
                }

                if (error.friendlyMessage) {
                    message.friendlyMessage = error.friendlyMessage
                }
                if (error.reason) {
                    message.reason = error.reason
                }
                if (error.code) {
                    message.code = error.code
                } else if (error.status) {
                    message.code = error.status
                }
            }
        } catch (ex) {
            /* istanbul ignore next */
            logger.error("App.renderError", ex)
        }

        // Send error JSON to client.
        res.status(status as number).json(message)

        /* istanbul ignore if */
        if (settings.app.events.render) {
            this.events.emit("renderError", req, res, error, status)
        }
    }
}

// Exports...
export default App.Instance
