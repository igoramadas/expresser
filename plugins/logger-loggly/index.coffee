# EXPRESSER LOGGER - LOGGLY
# --------------------------------------------------------------------------
fs = require "fs"
loggly = require "./loggly/index.js"
path = require "path"

lodash = null
logger = null
logglyClient = null
settings = null

###
# Loggly plugin for Expresser.
###
class LoggerLoggly
    priority: 1

    # INIT
    # --------------------------------------------------------------------------

    ###
    # Init the Loggly logging module. If default settings are defined on "settings.logger.loggly",
    # it will auto register itself to the main Logger as "loggly". Please note that this init
    # should be called automatically by the main Expresser `init()`.
    # @private
    ###
    init: ->
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        settings = @expresser.settings

        logger.drivers.loggly = this

        logger.debug "LoggerLoggly.init"

        # Auto register as "loggly" if a default token is defined on the settings.
        if settings.logger.loggly.enabled and settings.logger.loggly.token?
            logger.register "loggly", "loggly", settings.logger.loggly

        events.emit "LoggerLoggly.on.init"
        delete @init

    ###
    # Get the Loggly transport object.
    # @param {Object} options Loggly options.
    # @param {String} [options.token] Loggly access token, mandatory.
    # @param {String} [options.subdomain] Subdomain registered on Loggly, mandatory.
    # @param {Boolean} [options.json] Treat log parameters as JSON? Should be false unless you have very specific reasons.
    # @param {Boolean} [options.sendTimestamp] Send timestamp along log lines? Default is defined on settings.
    # @param {Function} [options.onLogSuccess] Function to execute on successful log calls, optional.
    # @param {Function} [options.onLogError] Function to execute on failed log calls, optional.
    # @return {Object} The Loggly logger transport.
    ###
    getTransport: (options) ->
        logger.debug "LoggerLoggly.getTransport", options

        if not settings.logger.loggly.enabled
            return logger.notEnabled "LoggerFile"

        if not options?.token? or options.token is ""
            return errors.throw tokenRequired, "Please set a valid options.token."

        if not options?.subdomain? or options.subdomain is ""
            return errors.throw domainRequired, "Please set a valid options.subdomain."

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

    ###
    # Loggly log method.
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
