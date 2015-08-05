# EXPRESSER LOGGER - LOGENTRIES
# --------------------------------------------------------------------------
# Logentries plugin for Expresser's Logger module.
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

    # Init the LoggerLogentries module. Verify which services are set, and add the necessary transports.
    # IP address and timestamp will be appended to logs depending on the settings.
    # @param [Object] options LoggerLogentries init options.
    init: (options) =>
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        moment = @expresser.libs.moment
        settings = @expresser.settings
        utils = @expresser.utils

        if settings.logger.logentries.enabled and settings.logger.logentries.token? and settings.logger.logentries.token isnt ""
            loggerLogentries = logentries.logger {token: settings.logger.logentries.token, timestamp: settings.logger.sendTimestamp}
            loggerLogentries.on("log", logger.onLogSuccess) if lodash.isFunction @onLogSuccess
            loggerLogentries.on("error", logger.onLogError) if lodash.isFunction @onLogError
            logger.activeServices.push "Logentries"

    # LOG METHODS
    # --------------------------------------------------------------------------

    # Generic log method.
    # @param [String] logType The log type (for example: warning, error, info, security, etc).
    # @param [String] logFunc Optional, the logging function name to be passed to the console and Logentries.
    # @param [Array] args Array of arguments to be stringified and logged.
    log: (logType, logFunc, args) =>
        if not args? and logFunc?
            args = logFunc
            logFunc = "info"

        # Get message out of the arguments.
        msg = @getMessage args

        # Log to different transports.
        if settings.logger.local.enabled and localBuffer?
            @logLocal logType, msg
        if settings.logger.logentries.enabled and loggerLogentries?
            loggerLogentries.log logFunc, msg
        if settings.logger.loggly.enabled and loggerLogentries?
            loggerLogentries.log msg, @logglyCallback

        # Log to the console depending on `console` setting.
        if settings.logger.console
            args.unshift moment().format "HH:mm:ss.SS"
            if settings.logger.errorLogTypes.indexOf(logType) >= 0
                console.error.apply this, args
            else
                console.log.apply this, args

    # Log to the active transports as `debug`, only if the debug flag is enabled.
    # All arguments are transformed to readable strings.
    debug: =>
        return if not settings.general.debug

        args = Array.prototype.slice.call arguments
        args.unshift "DEBUG"
        @log "debug", "info", args

    # Log to the active transports as `log`.
    # All arguments are transformed to readable strings.
    info: =>
        return if settings.logger.levels.indexOf("info") < 0

        args = Array.prototype.slice.call arguments
        args.unshift "INFO"
        @log "info", "info", args

    # Log to the active transports as `warn`.
    # All arguments are transformed to readable strings.
    warn: =>
        return if settings.logger.levels.indexOf("warn") < 0

        args = Array.prototype.slice.call arguments
        args.unshift "WARN"
        @log "warn", "warning", args

    # Log to the active transports as `error`.
    # All arguments are transformed to readable strings.
    error: =>
        return if settings.logger.levels.indexOf("error") < 0

        args = Array.prototype.slice.call arguments
        args.unshift "ERROR"
        @log "error", "err", args

    # Log to the active transports as `critical`.
    # All arguments are transformed to readable strings.
    critical: =>
        return if settings.logger.levels.indexOf("critical") < 0

        args = Array.prototype.slice.call arguments
        args.unshift "CRITICAL"
        @log "critical", "err", args

        # If the `criticalEmailTo` is set, dispatch a mail send event.
        if settings.logger.criticalEmailTo? and settings.logger.criticalEmailTo isnt ""
            body = args.join ", "
            maxAge = moment().subtract(settings.logger.criticalEmailExpireMinutes, "m").unix()

            # Do not proceed if this critical email was sent recently.
            return if @criticalEmailCache[body]? and @criticalEmailCache[body] > maxAge

            # Set mail options.
            mailOptions =
                subject: "CRITICAL: #{args[1]}"
                body: body
                to: settings.logger.criticalEmailTo
                logError: false

            # Emit mail send message.
            events.emit "Mailer.send", mailOptions, (err) ->
                console.error "LoggerLogentries.critical", "Can't send email!", err if err?

            # Save to critical email cache.
            @criticalEmailCache[body] = moment().unix()

# Singleton implementation
# --------------------------------------------------------------------------
LoggerLogentries.getInstance = ->
    @instance = new LoggerLogentries() if not @instance?
    return @instance

module.exports = exports = LoggerLogentries.getInstance()
