# EXPRESSER LOGGER - LOGENTRIES
# --------------------------------------------------------------------------
# Logentries plugin for Expresser.
# <!--
# @see settings.logger.logentries
# -->
class LoggerLogentries

    fs = require "fs"
    lodash = null
    logentries = require "node-logentries"
    logger = null
    path = require "path"
    settings = null

    # The Logentries transport object.
    loggerLogentries = null

    # INIT
    # --------------------------------------------------------------------------

    # Init the Logentries module. Verify which services are set, and add the necessary transports.
    # IP address and timestamp will be appended to logs depending on the settings.
    # @param {Object} options Logentries init options.
    init: (options) =>
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        settings = @expresser.settings

        logger.drivers.logentries = this

        options = {} if not options?
        options = lodash.defaultsDeep options, settings.logger.logentries

        # Auto register as "logentries" if a default token is defined on the settings.
        if options.enabled and options.token?
            return logger.register "logentries", "logentries", options

    # Get the transport object.
    # @param {Object} options Transport options including the token.
    getTransport: (options) =>
        if not options.token? or options.token is ""
            err = new Error "The options.token is mandatory! Please specify a valid Logentries token."
            logger.error "LoggerLogentries.getTransport", err, options
            throw err

        options = lodash.defaultsDeep options, settings.logger.logentries
        options.sendTimestamp = settings.logger.sendTimestamp if not options.sendTimestamp?
        options.onLogSuccess = logger.onLogSuccess if not options.onLogSuccess?
        options.onLogError = logger.onLogError if not options.onLogError?

        transport = {client: logentries.logger {token: options.token, timestamp: options.sendTimestamp}}
        transport.client.on("log", options.onLogSuccess) if lodash.isFunction options.onLogSuccess
        transport.client.on("error", options.onLogError) if lodash.isFunction options.onLogError

        return transport

    # LOG METHODS
    # --------------------------------------------------------------------------

    # Logentries log method.
    # @param {String} logType The log type (info, warn, error, debug, etc).
    # @param {Array} args Array or string to be logged.
    # @param {Boolean} avoidConsole If true it will NOT log to the console.
    log: (logType, args, avoidConsole) ->
        return if settings.logger.levels.indexOf(logType) < 0

        # Get message out of the arguments if not a string.
        if lodash.isString args
            message = args
        else
            message = logger.getMessage args

        @client.log logType, message

        # Log to the console depending on `console` setting.
        if settings.logger.console and not avoidConsole
            logger.console logType, args

# Singleton implementation
# --------------------------------------------------------------------------
LoggerLogentries.getInstance = ->
    @instance = new LoggerLogentries() if not @instance?
    return @instance

module.exports = exports = LoggerLogentries.getInstance()
