# EXPRESSER LOGGER
# --------------------------------------------------------------------------
# Handles server logging using local files, Logentries, Loggly and other
# transports available as plugins.
# Multiple services can be enabled at the same time.
# <!--
# @see settings.logger
# -->
class Logger

    events = require "./events.coffee"
    fs = require "fs"
    lodash = require "lodash"
    moment = require "moment"
    path = require "path"
    settings = require "./settings.coffee"
    utils = require "./utils.coffee"

    # PUBLIC PROPERTIES
    # --------------------------------------------------------------------------

    # @property {Object} Holds a list of available logging drivers.
    drivers: {}

    # @property {Object} List of registered transports.
    transports: {}

    # @property {Method} Custom (result) method to call when logs are sent to logging server or flushed to disk.
    onLogSuccess: null

    # @property {Method} Custom (err) method to call when errors are triggered by the logging transport.
    onLogError: null

    # INIT
    # --------------------------------------------------------------------------

    # Init the Logger module. Verify which services are set, and add the necessary transports.
    # IP address will be appended to logs depending on the settings.
    # @param {Object} options Logger init options.
    init: (options) =>
        if settings.logger.uncaughtException
            @debug "Logger.init", "Catching unhandled exceptions."

            process.on "uncaughtException", (err) =>
                try
                    @error "Unhandled exception!", err.message, err.stack
                catch ex
                    console.error "Unhandled exception!", err.message, err.stack, ex

        # TODO! Remove deprecation notice in Q2 2016!
        # The old `removeFields` setting is now called `settings.logger.obfuscateFields`.
        if settings.logger.removeFields?
            console.warn "Logger.init", "The logger.removeFields setting is deprecated, please use logger.obfuscateFields!"

        @setEvents() if settings.events.enabled

    # Bind events.
    setEvents: =>
        events.on "Logger.debug", @debug
        events.on "Logger.info", @info
        events.on "Logger.warn", @warn
        events.on "Logger.error", @error
        events.on "Logger.critical", @critical

    # IMPLEMENTATION
    # -------------------------------------------------------------------------

    # Register a Logger transport. This is called by Logger plugins.
    register: (id, driver, options) =>
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

    # LOG METHODS
    # --------------------------------------------------------------------------

    # Log to the console.
    # @param {String} logType The log type (for example: warning, error, info, security, etc).
    # @param {Array} args Array of arguments to be stringified and logged.
    # @return {String} The human readable log sent to the console.
    console: (logType, msg) =>
        args = @argsCleaner args
        timestamp = moment().format "HH:mm:ss.SS"

        if console[logType]?
            console[logType] timestamp, msg
        else
            console.log timestamp, msg

        return msg

    # Internal generic log method.
    # @param {String} logType The log type (for example: warning, error, info, security, etc).
    # @param {Array} args Array to be stringified and logged.
    log: (logType, args) =>
        return if settings.logger.levels.indexOf(logType) < 0 and not settings.general.debug

        # Get message out of the arguments.
        msg = @getMessage args

        # Dispatch to all registered transports.
        for key, obj of @transports
            obj.log logType, msg, true

        # Log to the console depending on `console` setting.
        if settings.logger.console
            @console logType, msg

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

    # Cleans the arguments passed according to the `removeFields` setting.
    # The maximum level deep down the object is defined by the `maxDeepLevel`.
    # @return {Arguments} Arguments with private fields obfuscated.
    # @private
    argsCleaner: ->
        funcText = "[Function]"
        max = settings.logger.maxDeepLevel - 1
        args = []

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
                    if index > max
                        obj[key] = "..."
                    else
                        if settings.logger.obfuscateFields?.indexOf(key) >=0
                            obj[key] = "***"
                        else if settings.logger.removeFields?.indexOf(key) >=0
                            delete obj[key]
                        else if lodash.isFunction value
                            obj[key] = funcText
                        else if lodash.isArray value
                            cleaner value[i], index + 1 while i < value.length
                        else if lodash.isObject value
                            cleaner value, index + 1

        # Iterate arguments and execute cleaner on objects.
        for a in arguments
            if lodash.isObject a or lodash.isArray a
                cloned = lodash.cloneDeep a
                cleaner cloned, 0
                args.push cloned
            else if lodash.isFunction a
                args.push funcText
            else
                args.push a

        return args

    # Returns a human readable message out of the arguments.
    # @return {String} The human readable, parsed JSON message.
    # @private
    getMessage: ->
        separated = []
        args = @argsCleaner arguments

        # Parse all arguments and stringify objects. Please note that fields defined
        # on the `removeFields` setting won't be added to the message.
        for a in args
            try
                if lodash.isObject a
                    stringified = JSON.stringify a, null, 2
                else
                    stringified = a.toString()
                separated.push stringified
            catch ex
                separated.push a.toString()

        # Append IP address, if `serverIP` is set.
        serverIP = utils.getServerIP true if settings.logger.sendIP
        separated.push "IP #{serverIP}" if serverIP?

        # Return single string log message.
        return separated.join settings.logger.separator

# Singleton implementation
# --------------------------------------------------------------------------
Logger.getInstance = ->
    return new Logger() if process.env is "test"
    @instance = new Logger() if not @instance?
    return @instance

module.exports = exports = Logger.getInstance()
