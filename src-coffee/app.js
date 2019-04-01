/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// EXPRESSER APP
// -----------------------------------------------------------------------------
const express = require("express");
const errors = require("./errors.coffee");
const events = require("./events.coffee");
const fs = require("fs");
const http = require("http");
const https = require("https");
const lodash = require("lodash");
const logger = require("./logger.coffee");
const path = require("path");
const settings = require("./settings.coffee");
const util = require("util");
const utils = require("./utils.coffee");

let nodeEnv = null;

/*
 * This is the "core" of an Expresser based application. The App wraps the
 * Express server and its middlewares / routes, along with a few extra helpers.
 */
var App = (function() {
    let getErrorMessage = undefined;
    App = class App {
        constructor() {
            this.init = this.init.bind(this);
            this.configure = this.configure.bind(this);
            this.start = this.start.bind(this);
            this.kill = this.kill.bind(this);
            this.all = this.all.bind(this);
            this.get = this.get.bind(this);
            this.post = this.post.bind(this);
            this.put = this.put.bind(this);
            this.patch = this.patch.bind(this);
            this.delete = this.delete.bind(this);
            this.listen = this.listen.bind(this);
            this.route = this.route.bind(this);
            this.use = this.use.bind(this);
            this.listRoutes = this.listRoutes.bind(this);
        }

        static initClass() {

            //#
            // Exposes the Express app object to the outside.
            // @property
            // @type express-Application
            this.prototype.expressApp = null;

            //#
            // The underlying HTTP(S) server.
            // @property
            // @type http-Server
            this.prototype.webServer = null;

            //#
            // The HTTP to HTTPS redirector server (only if settings.app.ssl.redirectorPort is set).
            // @property
            // @type http-Server
            this.prototype.redirectorServer = null;

            //#
            // Additional middlewares to be used by the Express server.
            // These will be called before the default middlewares.
            // @property
            // @type Array
            this.prototype.prependMiddlewares = [];

            //#
            // Additional middlewares to be used by the Express server.
            // These will be called after the default middlewares.
            // @property
            // @type Array
            this.prototype.appendMiddlewares = [];

            // Helper to build message out of the error object.
            getErrorMessage = function(obj) {
                if ((obj == null)) { return "Unhandled server error"; }
                if (lodash.isString(obj)) { return obj; }

                // Error might be wrapped inside a .error attribute.
                if ((obj.error != null) && (obj.message == null) && (obj.error_description == null) && (obj.reason == null)) {
                    obj = obj.error;
                }

                // Build error object.
                const msg = {};
                msg.message = obj.message || obj.error_description || obj.description || obj.toString();
                if (obj.friendlyMessage != null) { msg.friendlyMessage = obj.friendlyMessage; }
                if (obj.reason != null) { msg.reason = obj.reason; }
                if (obj.code != null) { msg.code = obj.code; }

                return msg;
            };
        }
        newInstance() { return new App(); }

        // INIT
        // --------------------------------------------------------------------------

        /*
         * Create, configure and run the Express application. In most cases this should be
         * the last step of you app loading, after loading custom modules, setting custom
         * configuration, etc. Please note that this will be called automatically if
         * you call the main `expresser.init()`.
         */
        init() {
            logger.debug("App.init");
            events.emit("App.before.init");

            nodeEnv = process.env.NODE_ENV;

            // Get version from main app's package.json (NOT Expresser, but the actual app using it!)
            try {
                if ((this.expresser != null ? this.expresser.rootPath : undefined)) {
                    this.version = __guard__(require(this.expresser.rootPath + "/package.json"), x => x.version);
                } else {
                    this.version = __guard__(require(__dirname + "../../package.json"), x1 => x1.version);
                }
            } catch (ex) {
                logger.error("App.init", "Could not fetch version from package.json.", ex);
            }

            // Configure the Express server.
            this.configure();

            // Start web server!
            this.start();

            events.emit("App.on.init");
            return delete this.init;
        }

        /*
         * Configure the server. Set views, options, use Express modules, etc.
         * Called automatically on `init()`, so normally you should never need
         * to call `configure()` on your own.
         * @private
         */
        configure() {
            let midErrorHandler, mw;
            const midBodyParser = require("body-parser");
            const midCookieParser = require("cookie-parser");
            const midCompression = require("compression");
            const midSession = require("express-session");

            if (settings.general.debug || (nodeEnv === "test")) {
                midErrorHandler = require("errorhandler");
            }

            // Create express v4 app.
            this.expressApp = express();

            // Trust proxy (mainly for secure cookies)?
            this.expressApp.set("trust proxy", settings.app.trustProxy);

            // BRAKING! Alert if user is still using old ./views default path for views.
            if (!fs.existsSync(settings.app.viewPath)) {
                logger.warn("Attention!", `Views path not found: ${settings.app.viewPath}`, "Note that the default path has changed from ./views/ to ./assets/views/");
            }

            // Set view options, use Pug for HTML templates.
            this.expressApp.set("views", settings.app.viewPath);
            this.expressApp.set("view engine", settings.app.viewEngine);
            this.expressApp.set("view options", { layout: false });

            // Prepend middlewares, if any was specified.
            if (this.prependMiddlewares.length > 0) {
                for (mw of Array.from(this.prependMiddlewares)) { this.expressApp.use(mw); }
            }

            // Use Express basic handlers.
            this.expressApp.use(midBodyParser.json({extended: true, limit: settings.app.bodyParser.limit}));
            this.expressApp.use(midBodyParser.urlencoded({extended: settings.app.bodyParser.extended, limit: settings.app.bodyParser.limit}));

            // Make sure we're using the correct session / cookie secret!
            if (settings.app.cookie.secret != null) {
                logger.deprecated("settings.app.cookie.secret", "Please set value on settings.app.secret.");
                settings.app.secret = settings.app.cookie.secret;
            }
            if (settings.app.session.secret != null) {
                logger.deprecated("settings.app.session.secret", "Please set value on settings.app.secret.");
                settings.app.secret = settings.app.session.secret;
            }

            if (settings.app.cookie.enabled) {
                this.expressApp.use(midCookieParser(settings.app.secret));
            }

            if (settings.app.session.enabled) {
                const memoryStore = require("memorystore")(midSession);

                this.expressApp.use(midSession({
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
                }));
            }

            // Use HTTP compression only if enabled on settings.
            if (settings.app.compression) {
                this.expressApp.use(midCompression);
            }

            // Fix connect assets helper context.
            const connectAssetsOptions = lodash.cloneDeep(settings.app.connectAssets);
            connectAssetsOptions.helperContext = this.expressApp.locals;

            // Connect assets and dynamic compiling.
            const ConnectAssets = (require("./app/connect-assets.js"))(connectAssetsOptions);
            this.expressApp.use(ConnectAssets);

            // Append extra middlewares, if any was specified.
            if (this.appendMiddlewares.length > 0) {
                for (mw of Array.from(this.appendMiddlewares)) { this.expressApp.use(mw); }
            }

            // Configure development environment to dump exceptions and show stack.
            if (settings.general.debug || (nodeEnv === "test")) {
                this.expressApp.use(midErrorHandler({dumpExceptions: true, showStack: true}));
            }

            // Use Express static routing.
            this.expressApp.use(express.static(settings.app.publicPath));

            // Log all requests if debug is true.
            if (settings.general.debug) {
                this.expressApp.use(function(req, res, next) {
                    const ip = utils.browser.getClientIP(req);
                    const { method } = req;
                    const { url } = req;

                    console.log(`Request from ${ip}`, method, url);

                    if (next != null) { next(); }

                    return url;
                });
            }

            // We should not call configure more than once!
            return delete this.configure;
        }

        // START AND KILL
        // --------------------------------------------------------------------------

        /*
         * Start the server using HTTP or HTTPS, depending on the settings.
         */
        start() {
            let serverRef;
            if (this.webServer != null) {
                return logger.warn("App.start", "Application has already started (webServer is not null). Abort!");
            }

            events.emit("App.before.start");

            if (settings.app.ssl.enabled && (settings.app.ssl.keyFile != null) && (settings.app.ssl.certFile != null)) {
                const sslKeyFile = utils.io.getFilePath(settings.app.ssl.keyFile);
                const sslCertFile = utils.io.getFilePath(settings.app.ssl.certFile);

                // Certificate files were found? Proceed, otherwise alert the user and throw an error.
                if ((sslKeyFile != null) && (sslCertFile != null)) {
                    if (fs.existsSync(sslKeyFile) && fs.existsSync(sslCertFile)) {
                        const sslKey = fs.readFileSync(sslKeyFile, {encoding: settings.general.encoding});
                        const sslCert = fs.readFileSync(sslCertFile, {encoding: settings.general.encoding});
                        const sslOptions = {key: sslKey, cert: sslCert};
                        serverRef = https.createServer(sslOptions, this.expressApp);
                    } else {
                        return errors.throw("certificatesNotFound", "Please check paths defined on settings.app.ssl.");
                    }
                } else {
                    return errors.throw("certificatesNotFound", "Please check paths defined on settings.app.ssl.");
                }
            } else {
                serverRef = http.createServer(this.expressApp);
            }

            // Expose the web server.
            this.webServer = serverRef;

            // Start the app!
            if ((settings.app.ip != null) && (settings.app.ip !== "")) {
                serverRef.listen(settings.app.port, settings.app.ip);
                serverRef.setTimeout(settings.app.timeout);
                logger.info("App", settings.app.title, `Listening on ${settings.app.ip} port ${settings.app.port}`);
            } else {
                serverRef.listen(settings.app.port);
                serverRef.setTimeout(settings.app.timeout);
                logger.info("App", settings.app.title, `Listening on port ${settings.app.port}`);
            }

            // Using SSL and redirector port is set? Then create the http server.
            if (settings.app.ssl.enabled && (settings.app.ssl.redirectorPort > 0)) {
                logger.info("App", `${settings.app.title} will redirect HTTP ${settings.app.ssl.redirectorPort} to HTTPS on ${settings.app.port}.`);

                const redirServer = express();
                redirServer.get("*", (req, res) => res.redirect(`https://${req.hostname}:${settings.app.port}${req.url}`));

                // Log all redirector requests if debug is true.
                if (settings.general.debug) {
                    redirServer.use(this.requestLogger);
                }

                this.redirectorServer = http.createServer(redirServer);
                this.redirectorServer.listen(settings.app.ssl.redirectorPort);
            }

            // Pass the HTTP(s) server created to external modules.
            return events.emit("App.on.start", serverRef);
        }

        /*
         * Kill the underlying HTTP(S) server(s).
         */
        kill() {
            events.emit("App.before.kill");

            try {
                if (this.webServer != null) {
                    this.webServer.close();
                }
                if (this.redirectorServer != null) {
                    this.redirectorServer.close();
                }
            } catch (ex) {
                logger.error("App.kill", ex);
            }

            this.webServer = null;
            this.redirectorServer = null;

            return events.emit("App.on.kill");
        }



        // HELPER AND UTILS
        // --------------------------------------------------------------------------

        /*
         * Return an array with all routes registered on the Express application.
         * @param {Boolean} asString If true, returns the route strings only, otherwise returns full objects.
         * @return {Array} Array with the routes (as object or as string if asString = true).
         */
        listRoutes(asString) {
            if (asString == null) { asString = false; }
            const result = [];

            for (let r of Array.from(this.expressApp._router.stack)) {
                if (((r.route != null ? r.route.path : undefined) != null) && (r.route.path !== "")) {
                    if (asString) {
                        result.push(r.route.path);
                    } else {
                        result.push({route: r.route.path, methods: lodash.keys(r.route.methods)});
                    }
                }
            }

            return result;
        }

        /*
         * Render a Pug view and send to the client.
         * @param {Object} req The Express request object, mandatory.
         * @param {Object} res The Express response object, mandatory.
         * @param {String} view The Pug view filename, mandatory.
         * @param {Object} options Options passed to the view, optional.
         */
        renderView(req, res, view, options) {
            logger.debug("App.renderView", req.originalUrl, view, options);

            try {
                if ((options == null)) { options = {}; }
                options.device = utils.browser.getDeviceDetails(req);
                if ((options.title == null)) { options.title = settings.app.title; }

                // View filename must jave .pug extension.
                if (view.indexOf(".pug") < 0) { view += ".pug"; }

                // Send rendered view to client.
                res.render(view, options);

            } catch (ex) {
                logger.error("App.renderView", view, ex);
                this.renderError(req, res, ex);
            }

            return events.emit("App.on.renderView", req, res, view, options);
        }

        /*
         * Sends pure text to the client.
         * @param {Object} req The Express request object, mandatory.
         * @param {Object} res The Express response object, mandatory.
         * @param {String} text The text to be rendered, mandatory.
         */
        renderText(req, res, text) {
            logger.debug("App.renderText", req.originalUrl, text);

            try {
                // Make sure text is a string!
                if ((text == null)) {
                    logger.debug("App.renderText", "Called with empty text parameter");
                    text = "";
                } else if (!lodash.isString(text)) {
                    text = text.toString();
                }

                res.setHeader("content-type", "text/plain");
                res.send(text);

            } catch (ex) {
                logger.error("App.renderText", text, ex);
                this.renderError(req, res, ex);
            }

            return events.emit("App.on.renderText", req, res, text);
        }

        /*
         * Render response as JSON data and send to the client.
         * @param {Object} req The Express request object, mandatory.
         * @param {Object} res The Express response object, mandatory.
         * @param {Object} data The JSON data to be sent, mandatory.
         */
        renderJson(req, res, data,status) {
            logger.debug("App.renderJson", req.originalUrl, data);

            if (lodash.isString(data)) {
                try {
                    data = JSON.parse(data);
                } catch (ex) {
                    return this.renderError(req, res, ex, 500);
                }
            }

            // Remove methods from JSON before rendering.
            var cleanJson = function(obj, depth) {
                if (depth > settings.logger.maxDepth) {
                    return;
                }

                if (lodash.isArray(obj)) {
                    return Array.from(obj).map((i) =>
                        cleanJson(i, depth + 1));
                } else if (lodash.isObject(obj)) {
                    return (() => {
                        const result = [];
                        for (let k in obj) {
                            const v = obj[k];
                            if (lodash.isFunction(v)) {
                                result.push(delete obj[k]);
                            } else {
                                result.push(cleanJson(v, depth + 1));
                            }
                        }
                        return result;
                    })();
                }
            };

            cleanJson(data, 0);

            // Add Access-Control-Allow-Origin to all when debug is true.
            if (settings.general.debug) {
                res.setHeader("Access-Control-Allow-Origin", "*");
            }

            // Send JSON response.
            res.json(data);

            return events.emit("App.on.renderJson", req, res, data);
        }

        /*
         * Render an image from the speficied file, and send to the client.
         * @param {Object} req The Express request object, mandatory.
         * @param {Object} res The Express response object, mandatory.
         * @param {String} filename The full path to the image file, mandatory.
         * @param {Object} options Options passed to the image renderer, for example the "mimetype".
         */
        renderImage(req, res, filename, options) {
            logger.debug("App.renderImage", req.originalUrl, filename, options);

            let mimetype = options != null ? options.mimetype : undefined;

            // Try to figure out the mime type in case it wasn't passed along the options.
            if ((mimetype == null)) {
                let extname = path.extname(filename).toLowerCase().replace(".","");
                if (extname === "jpg") { extname = "jpeg"; }
                mimetype = `image/${extname}`;
            }

            // Send image to client.
            res.contentType(mimetype);
            res.sendFile(filename);

            return events.emit("App.on.renderImage", req, res, filename, options);
        }

        /*
         * Sends error response as JSON.
         * @param {Object} req The Express request object, mandatory.
         * @param {Object} res The Express response object, mandatory.
         * @param {Object} error The error object or message to be sent to the client, mandatory.
         * @param {Number} status The response status code, optional, default is 500.
         */
        renderError(req, res, error, status) {
            let message;
            logger.debug("App.renderError", req.originalUrl, status, error);

            // Status default status.
            if ((status == null)) { status = (error != null ? error.statusCode : undefined) || 500; }
            if (status === "ETIMEDOUT") { status = 408; }

            try {
                message = getErrorMessage(error);
            } catch (ex) {
                logger.error("App.renderError", ex);
            }

            // Send error JSON to client.
            res.status(status).json({error: message, url: req.originalUrl});

            return events.emit("App.on.renderError", req, res, error, status);
        }
    };
    App.initClass();
    return App;
})();

// Singleton implementation
// -----------------------------------------------------------------------------
App.getInstance = function() {
    if ((this.instance == null)) { this.instance = new App(); }
    return this.instance;
};

module.exports = App.getInstance();

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
