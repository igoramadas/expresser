// Expresser: routes.ts

import app from "./app"
import _ = require("lodash")
import fs = require("fs")
import jaul = require("jaul")
import logger = require("anyhow")
const settings = require("setmeup").settings

/** Route loading options. */
interface LoadOptions {
    /** The actual routes implementation. */
    handlers: any
    /** The actual routes specs (for either plain routes or swagger). */
    specs?: any
    /** The file containing routes to be loaded. */
    filename?: string
    /** Optional version of the API / routes / swagger. */
    version?: string
}

/** Routes class (based on plain JSON or Swagger). */
export class Routes {
    private static _instance: Routes
    /** @hidden */
    static get Instance() {
        return this._instance || (this._instance = new this())
    }

    // BASIC IMPLEMENTATION
    // --------------------------------------------------------------------------

    /**
     * Load routes from the specified file.
     * @param options Loading options with filename or specs, and handlers.
     */
    load = (options: LoadOptions) => {
        let specs: any

        // Check if the handlers were passed.
        if (!options || !options.handlers) {
            throw new Error(`Missing options.handlers with the routing functions`)
        }

        logger.debug("Routes.load", options.filename, Object.keys(options.handlers))

        // Specs passed directly?
        if (options.specs) {
            specs = options.specs
        }
        // Otherwise load from filename.
        else {
            if (options.filename == null || options.filename == "") {
                options.filename = settings.routes.filename
            }

            // Try loading the routes file.
            try {
                const filename: string = jaul.io.getFilePath(options.filename)

                // Check if file exists.
                if (filename == null || !fs.existsSync(filename)) {
                    throw new Error(`File ${options.filename} not found.`)
                }
                specs = fs.readFileSync(filename, {encoding: settings.general.encoding}).toString()
                specs = JSON.parse(specs)
            } catch (ex) {
                logger.error("Routes.load", options.filename, ex)
                throw ex
            }
        }

        // Iterate routes and handlers.
        for (let [route, spec] of Object.entries(specs)) {
            if (_.isString(spec)) {
                spec = {get: spec}
            }

            for (let [method, handlerKey] of Object.entries(spec)) {
                const handler = options.handlers[handlerKey]

                // Make sure method and handler are valid.
                if (app[method] == null) {
                    logger.error("Routes.load", options.filename, route, `Invalid method: ${method}`)
                    throw new Error(`Invalid method: ${method}`)
                } else if (handler == null) {
                    logger.error("Routes.load", options.filename, route, `Invalid handler: ${handlerKey}`)
                    throw new Error(`Invalid handler: ${handlerKey}`)
                } else {
                    app[method](route, handler)
                    logger.info("Routes.load", options.filename, route, method, handlerKey)
                }
            }
        }
    }

    // SWAGGER IMPLEMENTATION
    // --------------------------------------------------------------------------

    /**
     * Load routes from a swagger definition file.
     * @param options Loading options.
     */
    loadSwagger = (options: LoadOptions) => {
        let specs: any

        // Check if the handlers were passed.
        if (!options || !options.handlers) {
            throw new Error(`Missing options.handlers with the routing functions`)
        }

        logger.debug("Routes.loadSwagger", options.filename, Object.keys(options.handlers))

        // Specs passed directly?
        if (options.specs) {
            specs = options.specs
        }
        // Otherwise load from filename.
        else {
            if (options.filename == null || options.filename == "") {
                options.filename = settings.routes.swagger.filename
            }

            // Try loading the swagger file.
            try {
                const filename: string = jaul.io.getFilePath(options.filename)

                // Check if swagger file exists.
                if (filename == null || !fs.existsSync(filename)) {
                    throw new Error(`File ${options.filename} not found.`)
                }

                specs = fs.readFileSync(filename, {encoding: settings.general.encoding}).toString()
                specs = JSON.parse(specs)
            } catch (ex) {
                logger.error("Routes.loadSwagger", options.filename, ex)
                throw ex
            }
        }

        // Version was passed as option?
        if (options.version != null) {
            specs.info.version = options.version
        }

        // Iterate and parse swagger specs.
        for (let [path, pathSpec] of Object.entries(specs.paths)) {
            path = path.toString().replace(/\/{/g, "/:")
            path = path.replace(/\}/g, "")

            for (let [method, methodSpec] of Object.entries(pathSpec)) {
                if (methodSpec == null) {
                    throw new Error(`Missing method spec for ${method} ${path}`)
                }

                // Handler not found for method?
                if (options.handlers[methodSpec.operationId] == null) {
                    throw new Error(`Missing route handler for ${methodSpec.operationId}`)
                }

                if (methodSpec.parameters == null) {
                    methodSpec.parameters = []
                }

                logger.info("Routes.loadSwagger", options.filename, method, path, methodSpec.operationId)

                // Create route on the app.
                app[method](path, (req, res, next) => {
                    try {
                        /* istanbul ignore if */
                        if (!req.swagger) {
                            req.swagger = {}
                        }

                        for (let parameterSpec of methodSpec.parameters) {
                            this.castParameter(req, parameterSpec)
                        }

                        options.handlers[methodSpec.operationId](req, res, next)
                    } catch (ex) {
                        /* istanbul ignore next */
                        logger.error("Routes", method, path, methodSpec.operationId, ex)
                    }
                })
            }
        }

        // Return specs when acessing /swagger.json.
        if (settings.routes.swagger.exposeJson) {
            app.get("/swagger.json", (_req, res) => res.json(specs))
        }
    }

    /**
     * Add parameters to the request swagger object. Internal use only.
     */
    private castParameter = function(req: any, spec: any) {
        try {
            const {name} = spec
            let scope, separator

            switch (spec.in) {
                case "query":
                    scope = "query"
                    break
                case "header":
                    scope = "header"
                    break
                case "path":
                    scope = "params"
                    break
            }

            // Parameter out of scope?
            if (scope == null) {
                return
            }

            req.swagger[scope] = req.swagger[scope] || {}
            const param = req[scope][name]

            // Parameter not found?
            if (param == null) {
                return
            }
            if (spec.type == "string") {
                if (spec.format == "date" || spec.format == "datetime" || spec.format == "date-time") {
                    req.swagger[scope][name] = new Date(param)
                } else {
                    req.swagger[scope][name] = param
                }
            } else if (spec.type == "number") {
                req.swagger[scope][name] = parseFloat(param)
            } else if (spec.type == "integer") {
                req.swagger[scope][name] = parseInt(param)
            } else if (spec.type == "boolean") {
                req.swagger[scope][name] = param
            } else if (spec.type == "array") {
                switch (spec.collectionFormat) {
                    case "csv":
                        separator = ","
                        break
                    case "ssv":
                        separator = " "
                        break
                    case "pipes":
                        separator = "|"
                        break
                }

                // Parameter format not found?
                if (separator == null) {
                    return
                }

                // Convert array types.
                req.swagger[scope][name] = param.split(separator)
            }
        } catch (ex) {
            /* istanbul ignore next */
            logger.error("Routes.castParameter", spec, ex)
        }
    }
}

// Exports...
export default Routes.Instance
