# EXPRESSER SWAGGER
# -----------------------------------------------------------------------------
fs = require "fs"

errors = null
events = null
lodash =  null
logger = null
settings = null
utils = null

###
# Implement routes based on a swagger template file.
###
class Swagger
    priority: 3

    ##
    # Swagger specs in JSON format.
    # @property
    # @type Object
    specs: null

    # INIT
    # --------------------------------------------------------------------------

    ###
    # Init the Swagger plugin.
    ###
    init: ->
        errors = @expresser.errors
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        settings = @expresser.settings
        utils = @expresser.utils

        logger.debug "Swagger.init"
        events.emit "Swagger.on.init"
        delete @init

    ###
    # Setup the swagger routes based on the template file.
    # Will load the specs from disk of not set yet.
    # @param {Object} handlers The handlers that correspond to the various operationIds of the swagger specs.
    # @param {Object} options Swagger setup options.
    # @param {String} [options.version] Force version on the swagger.json output.
    ###
    setup: (handlers, options) =>
        if not handlers?
            return errors.throw "The handlers argument is mandatory!"

        options = {} if not options?
        server = @expresser.app.expressApp

        logger.debug "Swagger.setup", Object.keys(handlers), options

        try
            pkg = require "../../package.json"
        catch ex
            logger.error "Swagger.setup", "Could not load app's package.json", ex

        # Specs not set yet? Try loading from disk.
        if not @specs?
            try
                filepath = utils.io.getFilePath settings.swagger.filename

                # Template swagger file exists, so load it.
                if filepath?
                    @specs = fs.readFileSync filepath, settings.general.encoding
                    @specs = JSON.parse @specs
            catch ex
                logger.error "Swagger.setup", filepath, ex

        # Swagger specs mandatory!
        if not @specs?
            return errors.throw "No swagger specs defined. Please set swagger.specs programatically, or define on the #{settings.swagger.filename} file."

        # Version was passed as option?
        if options.version?
            @specs.info.version = options.version
        # Auto match package version?
        else if settings.swagger.usePackageVersion
            @specs.info.version = pkg?.version

        # Iterate path specs.
        lodash.forOwn @specs.paths, (pathSpec, path) =>
            path = path.replace(/\/{/g, "/:").replace(/\}/g, "")

            lodash.forOwn pathSpec, (methodSpec, method) =>
                logger.info "Swagger.setup", method, path, methodSpec.operationId

                if not methodSpec?
                    return errors.throw "Missing method spec for #{method} #{path}"

                handler = handlers[methodSpec.operationId]

                # Handler not found for method?
                if not handler?
                    return errors.throw "Missing route handler for #{methodSpec.operationId}"

                methodSpec.parameters = [] if not methodSpec.parameters?

                # Create route on the app.
                server[method] path, (req, res, next) ->
                    req.swagger = {} if not req.swagger?
                    lodash.forEach methodSpec.parameters, (parameterSpec) -> castParameter req, parameterSpec
                    handler req, res, next

        # Return specs when acessing /swagger.json.
        server.get "/swagger.json", (req, res) => res.json @specs

    # IMPLEMENTATION
    # --------------------------------------------------------------------------

    # Add parameters to the request swagger object. Internal use only.
    castParameter = (req, spec) ->
        name = spec.name

        switch spec.in
            when "query"
                scope = "query"
            when "header"
                scope = "header"
            when "path"
                scope = "params"

        # Parameter out of scope?
        return if not scope?

        req.swagger[scope] = req.swagger[scope] or {}
        param = req[scope][name]

        # Parameter not found?
        return if not param?

        if spec.type is "string"
            if spec.format is "date" or spec.format is "date-time"
                req.swagger[scope][name] = new Date(param)
            else
                req.swagger[scope][name] = param

        if spec.type == "number"
            req.swagger[scope][name] = parseFloat param

        if spec.type == "integer"
            req.swagger[scope][name] = parseInt param

        if spec.type == "boolean"
            req.swagger[scope][name] = param

        if spec.type == "array"
            switch spec.collectionFormat
                when "csv"
                    separator = ","
                when "ssv"
                    separator = " "
                when "tsv"
                    separator = "\u0009"
                when "pipes"
                    separator = "|"

            # Parameter format not found?
            return if not separator?

            # Convert array types.
            req.swagger[scope][name] = param.split separator

        return true

# Singleton implementation
# --------------------------------------------------------------------------
Swagger.getInstance = ->
    @instance = new Swagger() if not @instance?
    return @instance

module.exports = exports = Swagger.getInstance()
