# EXPRESSER LOGGER - LOGENTRIES
# --------------------------------------------------------------------------
fs = require "fs"
logentries = require "node-logentries"
path = require "path"

lodash = null
logger = null
settings = null

###
# Logentries plugin for Expresser.
###
class LoggerLogentries
    priority: 1

    # INIT
    # --------------------------------------------------------------------------

    ###
    # Init the Logentries logging module. If default settings are defined on "settings.logger.logentries",
    # it will auto register itself to the main Logger as "logentries". Please note that this init
    # should be called automatically by the main Expresser `init()`.
    # @private
    ###
    init: ->
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        settings = @expresser.settings

        logger.drivers.logentries = this

        logger.debug "LoggerLogentries.init"

        # Auto register as "logentries" if a default token is defined on the settings.
        if settings.logger.logentries.enabled and settings.logger.logentries.token?
            logger.register "logentries", "logentries", settings.logger.logentries

        events.emit "LoggerLogentries.on.init"
        delete @init

    ###
    # Get the Logentries transport object.
    # @param {Object} options Logentries options.
    # @param {String} [options.token] Logentries access token, mandatory.
    # @param {Boolean} [options.sendTimestamp] Send timestamp along log lines? Default is defined on settings.
    # @param {Function} [options.onLogSuccess] Function to execute on successful log calls, optional.
    # @param {Function} [options.onLogError] Function to execute on failed log calls, optional.
    # @return {Object} The Logentries logger transport.
    ###
    getTransport: (options) ->
        logger.debug "LoggerLogentries.getTransport", options

        if not settings.logger.logentries.enabled
            return logger.notEnabled "LoggerFile"

        if not options?.token? or options.token is ""
            return errors.throw tokenRequired, "Please set a valid options.token."

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

    ###
    # Logentries log method.
    # @param {String} logType The log type (info, warn, error, debug, etc).
    # @param {Array} args Array or string to be logged.
    # @param {Boolean} avoidConsole If true it will NOT log to the console.
    ###
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
