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
# Handles server logging using the console, local files, Logentries, Loggly and
# other transports available as plugins. Multiple transports can be enabled at
# the same time.
###
class Logger
    newInstance: -> return new Logger()

    ##
    # List of available logging drivers. This list will be populated automatically by installed plugins.
    # @property
    # @type Object
    drivers: {}

    ##
    # List of registered transports.
    # @property
    # @type Object
    transports: {}

    ##
    # Method to call on every log request.
    # @property
    # @type Function
    onLog: null

    # INIT
    # --------------------------------------------------------------------------

    ###
    # Init the Logger module and set default settings.
    ###
    init: =>
        events.emit "Logger.before.init"

        if settings.logger.uncaughtException
            @debug "Logger.init", "Catching unhandled exceptions."

            process.on "uncaughtException", (err) =>
                try
                    @error "Unhandled exception!", err.message, err.stack
                catch ex
                    console.error "Unhandled exception!", err.message, err.stack, ex

        # DEPRECATED! Use settings.logger.maxDepth instead of maxDeepLevel.
        if settings.logger.maxDeepLevel?
            @deprecated "settings.logger.maxDeepLevel", "Please use settings.logger.maxDepth instead."
            settings.logger.maxDepth = settings.logger.maxDeepLevel

        events.emit "Logger.on.init"
        delete @init

    # IMPLEMENTATION
    # -------------------------------------------------------------------------

    ###
    # Register a Logger transport.
    # @param {String} id Unique ID of the transport to be registered, mandatory.
    # @param {String} driver The transport driver ID (logger, loggly, etc), mandatory.
    # @param {Object} options Registration options to be passed to the transport handler.
    ###
    register: (id, driver, options) ->
        if not @drivers[driver]?
            console.error "Logger.register", "#{driver} is not installed! Please check if plugin expresser-logger-#{driver} is available on the current environment."
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

    ###
    # Unregister a Logger transport.
    # @param {String} id Unique ID of the transport to be unregistered.
    ###
    unregister: (id) =>
        @transports[id]?.unregister?()
        delete @transports[id]

        if settings.general.debug
            console.log "Logger.unregister", id

    # LOG METHODS
    # --------------------------------------------------------------------------

    ###
    # Log to the console.
    # @param {String} logType The log type (ex: warning, error, info, etc).
    # @param {String} msg The message to be logged, mandatory.
    # @param {Boolean} doNotParse If true, message won't be cleaned using the `argsCleaner` helper.
    # @return {String} The human readable log sent to the console.
    ###
    console: (logType, msg, doNotParse = false) ->
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

    ###
    # Generic log method. You can use this if you want to have your own customized log types
    # instead of the more traditional debug / info / warning / error ...
    # @param {String} logType The log type (for example: info, error, myCustomType etc).
    # @param {Array} args Array to be stringified and logged, mandatory.
    # @return {String} The parsed, stringified log message.
    ###
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

    ###
    # Log to the active transports as `debug`, only if `settings.general.debug` is true.
    # @param {Arguments} args Any number of arguments to be parsed and stringified.
    ###
    debug: ->
        args = Array.prototype.slice.call arguments
        args.unshift "DEBUG"
        msg = @log "debug", args
        return msg

    ###
    # Log to the active transports as `info`.
    # @param {Arguments} args Any number of arguments to be parsed and stringified.
    ###
    info: ->
        args = Array.prototype.slice.call arguments
        args.unshift "INFO"
        msg = @log "info", args
        return msg

    ###
    # Log to the active transports as `warn`.
    # @param {Arguments} args Any number of arguments to be parsed and stringified.
    ###
    warn: ->
        args = Array.prototype.slice.call arguments
        args.unshift "WARN"
        msg = @log "warn", args
        events.emit "Logger.on.warn", msg
        return msg

    ###
    # Log to the active transports as `error`.
    # @param {Arguments} args Any number of arguments to be parsed and stringified.
    ###
    error: ->
        args = Array.prototype.slice.call arguments
        args.unshift "ERROR"
        msg = @log "error", args
        events.emit "Logger.on.error", msg
        return msg

    ###
    # Log to the active transports as `critical`.
    # @param {Arguments} args Any number of arguments to be parsed and stringified.
    ###
    critical: ->
        args = Array.prototype.slice.call arguments
        args.unshift "CRITICAL"
        msg = @log "critical", args
        events.emit "Logger.on.critical", msg
        return msg

    # HELPER METHODS
    # --------------------------------------------------------------------------

    ###
    # Helper to log to console about deprecated features.
    # @param {String} feature Module, function or feature that is deprecated, mandatory.
    # @param {String} message Optional message to add to the console.
    # @return {Object} Object on the format {error: 'Feature not enabled', notEnabled: true, message: '...'}
    ###
    deprecated: (feature, message) =>
        line = "#{feature} is deprecated. #{message}"
        @console "deprecated", line
        result = {error: "#{feature} is deprecated.", deprecated: true}
        result.message = message if message? and message isnt ""
        return result

    ###
    # Helper to log to console about features not enabled.
    # @param {String} feature Module, function or feature that is deprecated, mandatory.
    # @param {String} message Optional message to add to the console.
    # @return {Object} Object on the format {error: 'Feature not enabled', notEnabled: true, message: '...'}
    ###
    notEnabled: (feature, message) =>
        line = "#{feature} is not enabled. #{message}"
        @console "warn", line
        result = {error: "#{feature} is not enabled.", notEnabled: true}
        result.message = message if message? and message isnt ""
        return result

    ###
    # Process and clean arguments according to the `removeFields`, `maskFields`
    # and `obfuscateFields` settings. The maximum level deep down the object
    # is defined by the `maxDepth` setting.
    # @return {Arguments} Arguments with masked, hidden and obfuscated fields processed.
    # @private
    ###
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
                    cloned = lodash.cloneDeep arg
                    cleaner cloned, 0
                    result.push cloned

            catch ex
                console.warn "Logger.argsCleaner", argKey, ex

        return result

    ###
    # Parses arguments and returns a human readable message to be used for logging.
    # @param {Array} params Arguments or array of parameters to be parsed.
    # @return {String} The human readable, parsed JSON message.
    # @private
    ###
    getMessage: (params) ->
        separator = settings.logger.separator
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
                        arrError = []
                        arrError.push arg.friendlyMessage if arg.friendlyMessage?
                        arrError.push arg.reason if arg.reason?
                        arrError.push arg.code if arg.code?
                        arrError.push arg.message
                        arrError.push arg.stack
                        stringified = arrError.join separator
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
        if settings.logger.sendIP
            try
                serverIP = utils.network.getSingleIPv4() or utils.network.getSingleIPv6()
                serverIP = null if serverIP is ""
            catch ex
                serverIP = null

        separated.push "IP #{serverIP}" if serverIP?

        # Return single string log message.
        return separated.join separator

# Singleton implementation
# --------------------------------------------------------------------------
Logger.getInstance = ->
    @instance = new Logger() if not @instance?
    return @instance

module.exports = Logger.getInstance()
