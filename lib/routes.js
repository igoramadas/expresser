"use strict";
// Expresser: routes.ts
const _ = require("lodash");
const app = require("./app");
const fs = require("fs");
const jaul = require("jaul");
const logger = require("anyhow");
const settings = require("setmeup").settings;
/** Routes class (based on plain JSON or Swagger). */
class Routes {
    constructor() {
        // BASIC IMPLEMENTATION
        // --------------------------------------------------------------------------
        /**
         * Load routes from the specified file.
         * @param options Loading options with filename and handlers.
         */
        this.load = (options) => {
            logger.debug("Routes.load", options.filename, Object.keys(options.handlers));
            // Check if the handlers were passed.
            if (options.handlers == null) {
                throw new Error(`Missing options.handlers with the routing functions`);
            }
            // Default filename is taken from settings.
            if (options.filename == null || options.filename == "") {
                options.filename = settings.routes.filename;
            }
            const filename = jaul.io.getFilePath(options.filename);
            let jsonRoutes;
            // Check if file exists.
            if (filename == null || !fs.existsSync(filename)) {
                throw new Error(`File ${options.filename} not found.`);
            }
            // Try loading the routes file.
            try {
                jsonRoutes = fs.readFileSync(filename, { encoding: settings.general.encoding }).toString();
                jsonRoutes = JSON.parse(jsonRoutes);
            }
            catch (ex) {
                logger.error("Routes.load", filename, ex);
                throw ex;
            }
            // Iterate routes and handlers.
            for (let [route, spec] of Object.entries(jsonRoutes)) {
                if (_.isString(spec)) {
                    spec = { get: spec };
                }
                for (let [method, handlerKey] of Object.entries(spec)) {
                    const handler = options.handlers[handlerKey];
                    // Make sure method and handler are valid.
                    if (app[method] == null) {
                        logger.error("Routes.load", options.filename, route, `Invalid method: ${method}`);
                    }
                    else if (handler == null) {
                        logger.error("Routes.load", options.filename, route, `Invalid handler: ${handlerKey}`);
                    }
                    else {
                        app[method](route, handler);
                        logger.info("Routes.load", options.filename, route, method, handlerKey);
                    }
                }
            }
        };
        // SWAGGER IMPLEMENTATION
        // --------------------------------------------------------------------------
        /**
         * Load routes from a swagger definition file.
         * @param options Loading options.
         */
        this.loadSwagger = (options) => {
            logger.debug("Routes.loadSwagger", options.filename, Object.keys(options.handlers));
            // Check if the handlers were passed.
            if (options.handlers == null) {
                throw new Error(`Missing options.handlers with the routing functions`);
            }
            // Default swagger filename is taken from settings.
            if (options.filename == null || options.filename == "") {
                options.filename = settings.routes.swagger.filename;
            }
            const filename = jaul.io.getFilePath(options.filename);
            // Check if swagger file exists.
            if (filename == null || !fs.existsSync(filename)) {
                throw new Error(`File ${options.filename} not found.`);
            }
            let pkg, specs;
            // Try loading the package.json file.
            try {
                pkg = require(__dirname + "/../../../package.json");
            }
            catch (ex) {
                logger.error("Routes.loadSwagger", "Could not load app's main package.json", ex);
            }
            // Try loading the swagger file.
            try {
                specs = fs.readFileSync(filename, { encoding: settings.general.encoding }).toString();
                specs = JSON.parse(specs);
            }
            catch (ex) {
                logger.error("Routes.loadSwagger", filename, ex);
                throw ex;
            }
            // Version was passed as option?
            if (options.version != null) {
                specs.info.version = options.version;
            }
            else if (specs.info.version == null && pkg) {
                specs.info.version = pkg.version;
            }
            // Iterate and parse swagger specs.
            for (let [path, pathSpec] of Object.entries(specs.paths)) {
                path = path.toString().replace(/\/{/g, "/:");
                path = path.replace(/\}/g, "");
                for (let [method, methodSpec] of Object.entries(pathSpec)) {
                    if (methodSpec == null) {
                        throw new Error(`Missing method spec for ${method} ${path}`);
                    }
                    logger.info("Swagger.setup", method, path, methodSpec.operationId);
                    // Handler not found for method?
                    if (options.handlers[methodSpec.operationId] == null) {
                        throw new Error(`Missing route handler for ${methodSpec.operationId}`);
                    }
                    if (methodSpec.parameters == null) {
                        methodSpec.parameters = [];
                    }
                    // Create route on the app.
                    app[method](path, (req, res, next) => {
                        if (settings.swagger.castParameters) {
                            if (!req.swagger) {
                                req.swagger = {};
                            }
                            _.forEach(methodSpec.parameters, parameterSpec => this.castParameter(req, parameterSpec));
                        }
                        options.handlers[methodSpec.operationId](req, res, next);
                    });
                }
            }
            // Return specs when acessing /swagger.json.
            if (settings.routes.swagger.exposeJson) {
                app.get("/swagger.json", (_req, res) => res.json(specs));
            }
        };
        /**
         * Add parameters to the request swagger object. Internal use only.
         */
        this.castParameter = function (req, spec) {
            const { name } = spec;
            let scope, separator;
            switch (spec.in) {
                case "query":
                    scope = "query";
                    break;
                case "header":
                    scope = "header";
                    break;
                case "path":
                    scope = "params";
                    break;
            }
            // Parameter out of scope?
            if (scope == null) {
                return;
            }
            req.swagger[scope] = req.swagger[scope] || {};
            const param = req[scope][name];
            // Parameter not found?
            if (param == null) {
                return;
            }
            // Parse specs by type.
            try {
                if (spec.type == "string") {
                    if (spec.format == "date" || spec.format == "datetime" || spec.format == "date-time") {
                        req.swagger[scope][name] = new Date(param);
                    }
                    else {
                        req.swagger[scope][name] = param;
                    }
                }
                else if (spec.type == "number") {
                    req.swagger[scope][name] = parseFloat(param);
                }
                else if (spec.type == "integer") {
                    req.swagger[scope][name] = parseInt(param);
                }
                else if (spec.type == "boolean") {
                    req.swagger[scope][name] = param;
                }
                else if (spec.type == "array") {
                    switch (spec.collectionFormat) {
                        case "csv":
                            separator = ",";
                            break;
                        case "ssv":
                            separator = " ";
                            break;
                        case "tsv":
                            separator = "\u0009";
                            break;
                        case "pipes":
                            separator = "|";
                            break;
                    }
                    // Parameter format not found?
                    if (separator == null) {
                        return;
                    }
                    // Convert array types.
                    req.swagger[scope][name] = param.split(separator);
                }
            }
            catch (ex) {
                logger.error("Routes.castParameter", spec, ex);
            }
        };
    }
    /** @hidden */
    static get Instance() {
        return this._instance || (this._instance = new this());
    }
    /** Returns a new fresh instance of the Routes module. */
    newInstance() {
        return new Routes();
    }
}
module.exports = Routes.Instance;
