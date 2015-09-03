# EXPRESSER LOGGER - LOGGLY
# --------------------------------------------------------------------------
# Logger plugin to log to Loggly (www.loggly.com).
# <!--
# @see settings.logger.loggly
# -->
class LoggerLoggly

    fs = require "fs"
    loggly = require "loggly"
    path = require "path"
    lodash = null
    logger = null
    settings = null
    
    # Wrapper for the Loggly client.
    logglyClient = null

    # INIT
    # --------------------------------------------------------------------------

    # Init the Loggly module. Verify which services are set, and add the necessary transports.
    # IP address and timestamp will be appended to logs depending on the settings.
    # @param [Object] options LoggerLoggly init options.
    init: (options) =>
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        settings = @expresser.settings

        logger.drivers.loggly = this

        options = lodash.defaultsDeep options, settings.logger.loggly

        if options.enabled and options.token?
            return logger.register "loggly", "loggly", options

    # Get the transport object.
    # @param [Object] options Transport options including the token.
    getTransport: (options) =>
        if not options.token? or options.token is ""
            throw new Error "The options.token is mandatory! Please specify a valid Loggly token."

        if not options.subdomain? or options.subdomain is ""
            throw new Error "The options.subdomain is mandatory! Please specify a valid Loggly subdomain."

        options = lodash.defaultsDeep options, settings.logger.loggly
        options.sendTimestamp = settings.logger.sendTimestamp if not options.sendTimestamp
        options.json = false if not options.json?
        options.onLogSuccess = logger.onLogSuccess if not options.onLogSuccess?
        options.onLogError = logger.onLogError if not options.onLogError?

        transport = {client: loggly.createClient {token: options.token, subdomain: options.subdomain, json: options.json}}
        transport.onLogSuccess = options.onLogSuccess
        transport.onLogError = options.onLogError

        return transport

    # LOG METHODS
    # --------------------------------------------------------------------------

    # Loggly log method.
    # @param [String] logType The log type (info, warn, error, debug, etc).
    # @param [Array] args Array or string to be logged.
    # @param [Boolean] avoidConsole If true it will NOT log to the console.
    log: (logType, args, avoidConsole) ->
        return if settings.logger.levels.indexOf(logType) < 0

        # Get message out of the arguments if not a string.
        if lodash.isString args
            message = args
        else
            message = logger.getMessage args

        @client.log message, (err, result) =>
            if err?
                @onLogError? err
            else
                @onLogSuccess? result

        # Log to the console depending on `console` setting.
        if settings.logger.console and not avoidConsole
            logger.console logType, args

# Singleton implementation
# --------------------------------------------------------------------------
LoggerLoggly.getInstance = ->
    @instance = new LoggerLoggly() if not @instance?
    return @instance

module.exports = exports = LoggerLoggly.getInstance()
