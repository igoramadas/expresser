# EXPRESSER LOGGER - LOGENTRIES
# --------------------------------------------------------------------------
# Logentries plugin for Expresser.
# <!--
# @see settings.logger.logentries
# -->
class LoggerLogentries

    events = null
    fs = require "fs"
    lodash = null
    logentries = require "node-logentries"
    moment = null
    path = require "path"
    settings = null
    utils = null

    # The Logentries transport object.
    loggerLogentries = null

    # INIT
    # --------------------------------------------------------------------------

    # Init the Logentries module. Verify which services are set, and add the necessary transports.
    # IP address and timestamp will be appended to logs depending on the settings.
    # @param [Object] options Logentries init options.
    init: (options) =>
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        moment = @expresser.libs.moment
        settings = @expresser.settings
        utils = @expresser.utils

        logger.drivers.logentries = this

        if settings.logger.logentries.enabled and settings.logger.logentries.token?
            return logger.register "logentries", "logentries", settings.logger.logentries.token

    # Get the transport object.
    # @param [Object] options Transport options including the token.
    getTransport: (options) =>
        options.sendTimestamp = settings.logger.sendTimestamp if not options.sendTimestamp

        transport = logentries.logger {token: options.token, timestamp: options.sendTimestamp}
        transport.on("log", logger.onLogSuccess) if lodash.isFunction @onLogSuccess
        transport.on("error", logger.onLogError) if lodash.isFunction @onLogError

        return transport

    # LOG METHODS
    # --------------------------------------------------------------------------

    # Generic log method.
    # @param [String] logType The log type (for example: warning, error, info, security, etc).
    # @param [String] logFunc Optional, the logging function name to be passed to Logentries.
    # @param [Array] args Array of arguments to be stringified and logged.
    log: (logFunc, msg) =>
        if not msg?
            msg = logFunc
            logFunc = "info"

        loggerLogentries.log logFunc, msg

# Singleton implementation
# --------------------------------------------------------------------------
LoggerLogentries.getInstance = ->
    @instance = new LoggerLogentries() if not @instance?
    return @instance

module.exports = exports = LoggerLogentries.getInstance()
