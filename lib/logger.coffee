# EXPRESSER LOGGER
# --------------------------------------------------------------------------
chalk = require "chalk"
events = require "./events.coffee"
fs = require "fs"
lodash = require "lodash"
moment = require "moment"
path = require "path"
settings = require "./settings.coffee"
utils = require "./utils.coffee"

###
# Handles server logging using local files, Logentries, Loggly and other
# transports available as plugins. Multiple transports can be enabled at
# the same time.
###
class Logger
    newInstance: -> return new Logger()

    ##
    # List of available logging drivers.
    # @property {Object}
    drivers: {}

    ##
    # List of registered transports.
    # @property {Object}
    transports: {}

    ##
    # Method to call on every log request.
    # @property {Method}
    onLog: null

    # INIT
    # --------------------------------------------------------------------------

    # Init the Logger module. Verify which services are set, and add the necessary transports.
    # IP address will be appended to logs depending on the settings.
    init: =>
        events.emit "Logger.before.init"

        if settings.logger.uncaughtException
            @debug "Logger.init", "Catching unhandled exceptions."

            process.on "uncaughtException", (err) =>
                try
                    @error "Unhandled exception!", err.message, err.stack
                catch ex
                    console.error "Unhandled exception!", err.message, err.stack, ex

        # Deprecated settings.logger.maxDeepLevel in favour of maxDepth.
        if settings.logger.maxDeepLevel?
            @deprecated "settings.logger.maxDeepLevel", "Please use settings.logger.maxDepth."
            settings.logger.maxDepth = settings.logger.maxDeepLevel

        @setEvents()

        events.emit "Logger.on.init"
        delete @init

    # Bind events.
    setEvents: ->
        events.on "Logger.register", @register.bind(this)
        events.on "Logger.console", @console
        events.on "Logger.debug", @debug
        events.on "Logger.info", @info
        events.on "Logger.warn", @warn
        events.on "Logger.error", @error
        events.on "Logger.critical", @critical

    # IMPLEMENTATION
    # -------------------------------------------------------------------------

    # Register a Logger transport. This is called by Logger plugins.
    # @param {String} id Unique ID of the transport to be registered.
    register: (id, driver, options) ->
        if not @drivers[driver]?
            console.error "Logger.register", "The transport #{driver} is not installed! Please check if plugin expresser-logger-#{driver} is available on the current environment."
            return false
        else
            if settings.general.debug
                console.log "Logger.register", id, driver, options

            @transports[id] = @drivers[driver].getTransport options
            @transports[id].log = @drivers[driver].log
            @transports[id].debug = @debug
            @transports[id].info = @info
            @transports[id].warn = @warn
            @transports[id].error = @error
            @transports[id].critical = @critical

            return @transports[id]

    # Unregister a Logger transport.
    # @param {String} id Unique ID of the transport to be unregistered.
    unregister: (id) ->
        delete @transports[id]

    # LOG METHODS
    # --------------------------------------------------------------------------

    # Log to the console.
    # @param {String} logType The log type (for example: warning, error, info, security, etc).
    # @param {Array} args Array of arguments to be stringified and logged.
    # @param {Boolean} doNotParse If true, message won't be parsed and cleaned using the argsCleaner helper.
    # @return {String} The human readable log sent to the console.
    console: (logType, msg, doNotParse) ->
        return if process.env.NODE_ENV is "test" and logType isnt "test"

        timestamp = moment().format "HH:mm:ss.SS"

        # Only parse message if doNotClean is false or unset.
        msg = @getMessage msg if not doNotParse

        if console[logType]? and logType isnt "debug"
            method = console[logType]
        else
            method = console.log

        # Get styles (text colour, bold, italic etc...) for the correlated log type.
        styles = settings.logger.styles[logType]

        if styles?
            chalkStyle = chalk
            chalkStyle = chalkStyle[s] for s in styles
        else
            chalkStyle = chalk.white

        method timestamp, chalkStyle msg

        return msg

    # Internal generic log method.
    # @param {String} logType The log type (for example: warning, error, info, security, etc).
    # @param {Array} args Array to be stringified and logged.
    # @return {String} The human readable log line.
    log: (logType, args) ->
        return if settings.logger.levels?.indexOf(logType) < 0 and not settings.general.debug

        # Get message out of the arguments.
        msg = @getMessage args

        # Dispatch to all registered transports.
        for key, obj of @transports
            obj.log logType, msg, true

        # Log to the console depending on `console` setting.
        if settings.logger.console
            @console logType, msg, true

        # Custom onLog callback?
        @onLog? logType, args

        return msg

    # Log to the active transports as `debug`, only if the debug flag is enabled.
    # All arguments are transformed to readable strings.
    debug: ->
        args = Array.prototype.slice.call arguments
        args.unshift "DEBUG"
        @log "debug", args

    # Log to the active transports as `info`.
    # All arguments are transformed to readable strings.
    info: ->
        args = Array.prototype.slice.call arguments
        args.unshift "INFO"
        @log "info", args

    # Log to the active transports as `warn`.
    # All arguments are transformed to readable strings.
    warn: ->
        args = Array.prototype.slice.call arguments
        args.unshift "WARN"
        @log "warn", args

    # Log to the active transports as `error`.
    # All arguments are transformed to readable strings.
    error: ->
        args = Array.prototype.slice.call arguments
        args.unshift "ERROR"
        @log "error", args

    # Log to the active transports as `critical`.
    # All arguments are transformed to readable strings.
    critical: ->
        args = Array.prototype.slice.call arguments
        args.unshift "CRITICAL"
        @log "critical", args

    # HELPER METHODS
    # --------------------------------------------------------------------------

    # Helper to log to console about methods / features deprecation.
    deprecated: (func, message) ->
        message = "#{func} is deprecated. #{message}"
        @console "deprecated", message
        return {error: "Deprecated", message: message}

    # Helper to log to console that module is not enabled on settings.
    notEnabled: (module, func) ->
        @console "debug", "#{module}.#{func} abort! #{module} is not enabled."
        return {error: "Module #{module} is not enabled.", notEnabled: true}

    # Cleans the arguments passed according to the `removeFields` setting.
    # The maximum level deep down the object is defined by the `maxDeepLevel`.
    # @return {Arguments} Arguments with private fields obfuscated.
    # @private
    argsCleaner: ->
        funcText = "[Function]"
        unreadableText = "[Unreadable]"
        max = settings.logger.maxDepth - 1
        result = []

        # Recursive cleaning function.
        cleaner = (obj, index) ->
            i = 0

            if lodash.isArray obj
                while i < obj.length
                    if index > max
                        obj[i] = "..."
                    else if lodash.isFunction obj[i]
                        obj[i] = funcText
                    else
                        cleaner obj[i], index + 1
                    i++

            else if lodash.isObject obj
                for key, value of obj
                    try
                        if index > max
                            obj[key] = "..."
                        else if settings.logger.obfuscateFields?.indexOf(key) >=0
                            obj[key] = "***"
                        else if settings.logger.maskFields?[key]?
                            if lodash.isObject value
                                maskedValue = value.value or value.text or value.contents or value.data or ""
                            else
                                maskedValue = value.toString()
                            obj[key] = utils.data.maskString maskedValue, "*", settings.logger.maskFields[key]
                        else if settings.logger.removeFields?.indexOf(key) >=0
                            delete obj[key]
                        else if lodash.isArray value
                            while i < value.length
                                cleaner value[i], index + 1
                                i++
                        else if lodash.isFunction value
                            obj[key] = funcText
                        else if lodash.isObject value
                            cleaner value, index + 1
                    catch ex
                        delete obj[key]
                        obj[key] = unreadableText

        # Iterate arguments and execute cleaner on objects.
        for argKey, arg of arguments
            try
                if lodash.isArray arg
                    for a in arg
                        if lodash.isError a
                            result.push a
                        else if lodash.isObject a
                            cloned = lodash.cloneDeep a
                            cleaner cloned, 0
                            result.push cloned
                        else if lodash.isFunction a
                            result.push funcText
                        else
                            result.push a
                else
                    result.push a

            catch ex
                console.warn "Logger.argsCleaner", argKey, ex

        return result

    # Returns a human readable message out of the arguments.
    # @return {String} The human readable, parsed JSON message.
    # @private
    getMessage: (params) ->
        separated = []
        args = []

        if arguments.length > 1
            args.push value for value in arguments
        else if lodash.isArray params
            args.push value for value in params
        else
            args.push params

        args = @argsCleaner args

        # Parse all arguments and stringify objects. Please note that fields defined
        # on the `removeFields` setting won't be added to the message.
        for arg in args
            if arg?
                stringified = ""

                try
                    if lodash.isArray arg
                        for value in arg
                            stringified += JSON.stringify value, null, 2
                    else if lodash.isError arg
                        stringified = arg.message + " " + arg.stack
                    else if lodash.isObject arg
                        stringified = JSON.stringify arg, null, 2
                    else
                        stringified = arg.toString()
                catch ex
                    stringified = arg.toString()

                # Compact log lines?
                if settings.logger.compact
                    stringified = stringified.replace(/(\r\n|\n|\r)/gm, "").replace(/  +/g, " ");

                separated.push stringified

        # Append IP address, if `serverIP` is set.
        try
            serverIP = utils.system.getIP true if settings.logger.sendIP
            serverIP = null if serverIP.error
        catch ex
            serverIP = null

        separated.push "IP #{serverIP}" if serverIP?

        separator = settings.logger.separator

        # Return single string log message.
        return separated.join separator

# Singleton implementation
# --------------------------------------------------------------------------
Logger.getInstance = ->
    @instance = new Logger() if not @instance?
    return @instance

module.exports = Logger.getInstance()
