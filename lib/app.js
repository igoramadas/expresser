"use strict";
// Expresser: app.ts
const _ = require("lodash");
const EventEmitter = require("eventemitter3");
const express = require("express");
const fs = require("fs");
const http = require("http");
const https = require("https");
const jaul = require("jaul");
const logger = require("anyhow");
const path = require("path");
const setmeup = require("setmeup");
let settings;
/** Main App class. */
class App {
    /** Default App constructor. */
    constructor() {
        /** Event emitter. */
        this.events = new EventEmitter();
        // RENDERING METHODS
        // --------------------------------------------------------------------------
        /**
         * Render a view and send to the client. The view engine depends on the settings defined.
         * @param req The Express request object.
         * @param res The Express response object.
         * @param view The view filename.
         * @param options Options passed to the view, optional.
         * @event renderView
         */
        this.renderView = (req, res, view, options) => {
            logger.debug("App.renderView", req.originalUrl, view, options);
            try {
                if (!options) {
                    options = {};
                }
                if (options.title == null) {
                    options.title = settings.app.title;
                }
                // Send rendered view to client.
                res.render(view, options);
            }
            catch (ex) {
                /* istanbul ignore next */
                logger.error("App.renderView", view, ex);
                /* istanbul ignore next */
                this.renderError(req, res, ex);
            }
            if (settings.app.events.render) {
                this.events.emit("renderView", req, res, view, options);
            }
        };
        /**
         * Sends pure text to the client.
         * @param req The Express request object.
         * @param res The Express response object.
         * @param text The text to be rendered, mandatory.
         * @event renderText
         */
        this.renderText = (req, res, text) => {
            logger.debug("App.renderText", req.originalUrl, text);
            try {
                if (text == null) {
                    logger.debug("App.renderText", "Called with empty text parameter");
                    text = "";
                }
                else if (!_.isString(text)) {
                    text = text.toString();
                }
                res.setHeader("content-type", "text/plain");
                res.send(text);
            }
            catch (ex) {
                /* istanbul ignore next */
                logger.error("App.renderText", text, ex);
                /* istanbul ignore next */
                this.renderError(req, res, ex);
            }
            if (settings.app.events.render) {
                this.events.emit("renderText", req, res, text);
            }
        };
        /**
         * Render response as JSON data and send to the client.
         * @param req The Express request object.
         * @param res The Express response object.
         * @param data The JSON data to be sent.
         * @event renderJson
         */
        this.renderJson = (req, res, data) => {
            logger.debug("App.renderJson", req.originalUrl, data);
            if (_.isString(data)) {
                try {
                    data = JSON.parse(data);
                }
                catch (ex) {
                    logger.error("App.renderJson", ex);
                    return this.renderError(req, res, ex, 500);
                }
            }
            // Remove methods from JSON before rendering.
            var cleanJson = function (obj, depth) {
                if (depth >= settings.logger.maxDepth) {
                    return;
                }
                if (_.isArray(obj)) {
                    return Array.from(obj).map(i => cleanJson(i, depth + 1));
                }
                else if (_.isObject(obj)) {
                    return (() => {
                        const result = [];
                        for (let k in obj) {
                            const v = obj[k];
                            if (_.isFunction(v)) {
                                result.push(delete obj[k]);
                            }
                            else {
                                result.push(cleanJson(v, depth + 1));
                            }
                        }
                        return result;
                    })();
                }
            };
            cleanJson(data, 0);
            // Add Access-Control-Allow-Origin if set.
            if (settings.app.allowOriginHeader) {
                res.setHeader("Access-Control-Allow-Origin", settings.app.allowOriginHeader);
            }
            // Send JSON response.
            res.json(data);
            if (settings.app.events.render) {
                this.events.emit("renderJson", req, res, data);
            }
        };
        /**
         * Render an image from the speficied file, and send to the client.
         * @param req The Express request object.
         * @param res The Express response object.
         * @param filename The full path to the image file.
         * @param options Options passed to the image renderer, for example the "mimetype".
         * @event renderImage
         */
        this.renderImage = (req, res, filename, options) => {
            logger.debug("App.renderImage", req.originalUrl, filename, options);
            let mimetype = options ? options.mimetype : null;
            // Try to figure out the mime type in case it wasn't passed along the options.
            if (!mimetype) {
                let extname = path
                    .extname(filename)
                    .toLowerCase()
                    .replace(".", "");
                if (extname == "jpg") {
                    extname = "jpeg";
                }
                mimetype = `image/${extname}`;
            }
            // Send image to client.
            res.type(mimetype);
            res.sendFile(filename);
            if (settings.app.events.render) {
                this.events.emit("renderImage", req, res, filename, options);
            }
        };
        /**
         * Sends error response as JSON.
         * @param req The Express request object.
         * @param res The Express response object.
         * @param error The error object or message to be sent to the client.
         * @param status The response status code, optional, default is 500.
         * @event renderError
         */
        this.renderError = (req, res, error, status) => {
            let message;
            logger.debug("App.renderError", req.originalUrl, status, error);
            /* istanbul ignore next */
            if (typeof error == "undefined" || error == null) {
                error = "Unknown error";
                logger.warn("App.renderError", "Called with null error");
            }
            // Status default statuses.
            if (status == null) {
                status = error.statusCode || error.status || error.code;
            }
            if (status == "ETIMEDOUT") {
                status = 408;
            }
            // Error defaults to 500 if not a valid number.
            if (!_.isNumber(status)) {
                status = 500;
            }
            try {
                // Error inside another .error property?
                if (error.error && !error.message && !error.error_description && !error.reason) {
                    error = error.error;
                }
                if (_.isString(error)) {
                    message = { message: error };
                }
                else {
                    message = {};
                    message.message = error.message || error.error_description || error.description;
                    // No message found? Just use the default .toString() then.
                    /* istanbul ignore next */
                    if (!message.message) {
                        message.message = error.toString();
                    }
                    if (error.friendlyMessage) {
                        message.friendlyMessage = error.friendlyMessage;
                    }
                    if (error.reason) {
                        message.reason = error.reason;
                    }
                    if (error.code) {
                        message.code = error.code;
                    }
                    else if (error.status) {
                        message.code = error.status;
                    }
                }
            }
            catch (ex) {
                /* istanbul ignore next */
                logger.error("App.renderError", ex);
            }
            // Send error JSON to client.
            res.status(status).json(message);
            if (settings.app.events.render) {
                this.events.emit("renderError", req, res, error, status);
            }
        };
        if (!logger.isReady) {
            /* istanbul ignore next */
            logger.setup();
        }
        // Load default settings.
        setmeup.load(__dirname + "/../settings.default.json", { overwrite: false });
        settings = setmeup.settings;
    }
    /** @hidden */
    static get Instance() {
        return this._instance || (this._instance = new this());
    }
    /** Returns a new fresh instance of the App module. */
    newInstance() {
        return new App();
    }
    // EVENTS
    // --------------------------------------------------------------------------
    /**
     * Bind callback to event. Shortcut to `events.on()`.
     * @param eventName The name of the event.
     * @param callback Callback function.
     */
    on(eventName, callback) {
        this.events.on(eventName, callback);
    }
    /**
     * Bind callback to event that will be triggered only once. Shortcut to `events.once()`.
     * @param eventName The name of the event.
     * @param callback Callback function.
     */
    once(eventName, callback) {
        this.events.on(eventName, callback);
    }
    /**
     * Unbind callback from event. Shortcut to `events.off()`.
     * @param eventName The name of the event.
     * @param callback Callback function.
     */
    off(eventName, callback) {
        this.events.off(eventName, callback);
    }
    // MAIN METHODS
    // --------------------------------------------------------------------------
    /**
     * Init the app module and start the HTTP(S) server.
     * @param middlewares List of middlewares to be appended / prepended.
     * @event init
     */
    init(middlewares) {
        let mw;
        // Set preprocessor, if not set yet.
        if (!logger.preprocessor) {
            logger.preprocessor = require("./logger").clean;
        }
        logger.errorStack = settings.logger.errorStack;
        // Create express v4 app.
        this.expressApp = express();
        middlewares = middlewares || { append: [], prepend: [] };
        // Make sure passed middlewares are array based.
        if (middlewares.prepend && !_.isArray(middlewares.prepend)) {
            middlewares.prepend = [middlewares.prepend];
        }
        if (middlewares.append && !_.isArray(middlewares.append)) {
            middlewares.append = [middlewares.append];
        }
        // Prepend middlewares?
        if (middlewares.prepend && middlewares.prepend.length > 0) {
            for (mw of middlewares.prepend) {
                if (mw) {
                    this.expressApp.use(mw);
                    logger.debug("App.init", "Prepended middleware");
                }
            }
        }
        // Trust proxy (mainly for secure cookies)?
        this.expressApp.set("trust proxy", settings.app.trustProxy);
        // Default view path.
        this.expressApp.set("views", settings.app.viewPath);
        // Set view options, use Pug for HTML templates.
        if (settings.app.viewEngine) {
            this.expressApp.set("view engine", settings.app.viewEngine);
            this.expressApp.set("view options", settings.app.viewOptions);
        }
        // Use body parser?
        if (settings.app.bodyParser && settings.app.bodyParser.enabled) {
            try {
                const midBodyParser = require("body-parser");
                this.expressApp.use(midBodyParser.json({ extended: settings.app.bodyParser.extended, limit: settings.app.bodyParser.limit }));
                this.expressApp.use(midBodyParser.urlencoded({ extended: settings.app.bodyParser.extended, limit: settings.app.bodyParser.limit }));
            }
            catch (ex) {
                /* istanbul ignore next */
                logger.warn("App.init", "Can't load 'body-parser' module.");
            }
        }
        // Cookies enabled? Depends on `cookie-parser` being installed.
        if (settings.app.cookie && settings.app.cookie.enabled) {
            try {
                const midCookieParser = require("cookie-parser");
                this.expressApp.use(midCookieParser(settings.app.secret));
            }
            catch (ex) {
                /* istanbul ignore next */
                ex.friendlyMessage = "Can't load 'cookie-parser' module.";
                /* istanbul ignore next */
                logger.error("App.init", ex);
            }
        }
        // Session enabled?
        if (settings.app.session && settings.app.session.enabled) {
            try {
                const midSession = require("express-session");
                const memoryStore = require("memorystore")(midSession);
                this.expressApp.use(midSession({
                    store: new memoryStore({ checkPeriod: settings.app.session.checkPeriod }),
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
                }));
            }
            catch (ex) {
                /* istanbul ignore next */
                ex.friendlyMessage = "Can't load 'express-session' and 'memorystore' modules.";
                /* istanbul ignore next */
                logger.error("App.init", ex);
            }
        }
        // Use HTTP compression only if enabled on settings.
        if (settings.app.compression && settings.app.compression.enabled) {
            try {
                const midCompression = require("compression");
                this.expressApp.use(midCompression());
            }
            catch (ex) {
                /* istanbul ignore next */
                ex.friendlyMessage = "Can't load 'compression' module.";
                /* istanbul ignore next */
                logger.error("App.init", ex);
            }
        }
        // Use Express static routing.
        if (settings.app.publicPath) {
            this.expressApp.use(express.static(settings.app.publicPath));
        }
        // Append middlewares?
        if (middlewares.append && middlewares.append.length > 0) {
            for (mw of middlewares.append) {
                if (mw) {
                    this.expressApp.use(mw);
                    logger.debug("App.init", "Appended middleware");
                }
            }
        }
        // Log all requests if debug is true.
        if (settings.general.debug) {
            this.expressApp.use(function (req, res, next) {
                const { method } = req;
                const { url } = req;
                const ip = jaul.network.getClientIP(req);
                const msg = `Request from ${ip}`;
                if (res) {
                    logger.debug("App", msg, method, url);
                }
                if (next) {
                    next();
                }
                return url;
            });
        }
        // Dispatch init event, and start the server.
        this.events.emit("init");
        this.start();
    }
    /**
     * Start the HTTP(S) server.
     * @returns The HTTP(S) server created by Express.
     * @event start
     */
    start() {
        if (this.server) {
            logger.warn("App.start", "Server is already running, abort start.");
            return this.server;
        }
        let serverRef;
        if (settings.app.ssl && settings.app.ssl.enabled && settings.app.ssl.keyFile && settings.app.ssl.certFile) {
            const sslKeyFile = jaul.io.getFilePath(settings.app.ssl.keyFile);
            const sslCertFile = jaul.io.getFilePath(settings.app.ssl.certFile);
            // Certificate files were found? Proceed, otherwise alert the user and throw an error.
            if (sslKeyFile && sslCertFile) {
                const sslKey = fs.readFileSync(sslKeyFile, { encoding: settings.general.encoding });
                const sslCert = fs.readFileSync(sslCertFile, { encoding: settings.general.encoding });
                const sslOptions = { key: sslKey, cert: sslCert };
                serverRef = https.createServer(sslOptions, this.expressApp);
            }
            else {
                throw new Error("Invalid certificate filename, please check paths defined on settings.app.ssl.");
            }
        }
        else {
            serverRef = http.createServer(this.expressApp);
        }
        // Expose the web server.
        this.server = serverRef;
        let listenCb = () => {
            if (settings.app.ip) {
                logger.info("App.start", settings.app.title, `Listening on ${settings.app.ip} port ${settings.app.port}`, `URL ${settings.app.url}`);
            }
            else {
                logger.info("App.start", settings.app.title, `Listening on port ${settings.app.port}`, `URL ${settings.app.url}`);
            }
        };
        /* istanbul ignore next */
        let listenError = err => {
            /* istanbul ignore next */
            logger.error("App.start", "Can't start", err);
        };
        // Start the app!
        if (settings.app.ip) {
            serverRef.listen(settings.app.port, settings.app.ip, listenCb).on("error", listenError);
        }
        else {
            serverRef.listen(settings.app.port, listenCb).on("error", listenError);
        }
        // Set default timeout.
        serverRef.timeout = settings.app.timeout;
        // Emit start event and return HTTP(S) server.
        this.events.emit("start");
        return this.server;
    }
    /**
     * Kill the underlying HTTP(S) server(s).
     * @event kill
     */
    kill() {
        if (!this.server) {
            logger.warn("App.kill", "Server was not running");
            return;
        }
        try {
            this.server.close();
            this.server = null;
            this.events.emit("kill");
        }
        catch (ex) {
            /* istanbul ignore next */
            logger.error("App.kill", ex);
        }
    }
    // BRIDGED METHODS
    // --------------------------------------------------------------------------
    /**
     * Shortcut to express ".all()".
     * @param reqPath The path for which the middleware function is invoked.
     * @param callbacks Single, array or series of middlewares.
     */
    all(reqPath, ...callbacks) {
        logger.debug("App.all", reqPath, ...callbacks);
        return this.expressApp.all.apply(this.expressApp, arguments);
    }
    /**
     * Shortcut to express ".get()".
     * @param reqPath The path for which the middleware function is invoked.
     * @param callbacks Single, array or series of middlewares.
     */
    get(reqPath, ...callbacks) {
        logger.debug("App.get", reqPath, ...callbacks);
        return this.expressApp.get.apply(this.expressApp, arguments);
    }
    /**
     * Shortcut to express ".post()".
     * @param reqPath The path for which the middleware function is invoked.
     * @param callbacks Single, array or series of middlewares.
     */
    post(reqPath, ...callbacks) {
        logger.debug("App.post", reqPath, ...callbacks);
        return this.expressApp.post.apply(this.expressApp, arguments);
    }
    /**
     * Shortcut to express ".put()".
     * @param reqPath The path for which the middleware function is invoked.
     * @param callbacks Single, array or series of middlewares.
     */
    put(reqPath, ...callbacks) {
        logger.debug("App.put", reqPath, ...callbacks);
        return this.expressApp.put.apply(this.expressApp, arguments);
    }
    /**
     * Shortcut to express ".patch()".
     * @param reqPath The path for which the middleware function is invoked.
     * @param callbacks Single, array or series of middlewares.
     */
    patch(reqPath, ...callbacks) {
        logger.debug("App.patch", reqPath, ...callbacks);
        return this.expressApp.patch.apply(this.expressApp, arguments);
    }
    /**
     * Shortcut to express ".delete()".
     * @param reqPath The path for which the middleware function is invoked.
     * @param callbacks Single, array or series of middlewares.
     */
    delete(reqPath, ...callbacks) {
        logger.debug("App.delete", reqPath, ...callbacks);
        return this.expressApp.delete.apply(this.expressApp, arguments);
    }
    /**
     * Shortcut to express ".use()".
     * @param reqPath The path for which the middleware function is invoked.
     * @param callbacks Single, array or series of middlewares.
     */
    use(reqPath, ...callbacks) {
        logger.debug("App.use", reqPath, ...callbacks);
        return this.expressApp.use.apply(this.expressApp, arguments);
    }
    /**
     * Shortcut to express ".route()".
     * @param reqPath The path of the desired route.
     * @returns An instance of a single route for the specified path.
     */
    route(reqPath) {
        logger.debug("App.route", reqPath);
        return this.expressApp.route.apply(this.expressApp, arguments);
    }
}
module.exports = App.Instance;
