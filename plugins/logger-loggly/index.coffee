# EXPRESSER LOGGER - LOGGLY
# --------------------------------------------------------------------------
# Logger plugin to log to Loggly (www.loggly.com).
# <!--
# @see Settings.logger.loggly
# -->
class LoggerLoggly

    fs = require "fs"
    loggly = require "loggly"
    path = require "path"
    lodash = null
    logger = null
    settings = null
    utils = null
    
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

        if settings.logger.loggly.enabled and settings.logger.loggly.subdomain? and settings.logger.loggly.token? and settings.logger.loggly.token isnt ""
            logglyClient = loggly.createClient {token: settings.logger.loggly.token, subdomain: settings.logger.loggly.subdomain, json: false}

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
        if settings.logger.loggly.enabled and logglyClient?
            logglyClient.log msg, @logglyCallback

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
                console.error "LoggerLoggly.critical", "Can't send email!", err if err?

            # Save to critical email cache.
            @criticalEmailCache[body] = moment().unix()

    # LOCAL LOGGING
    # --------------------------------------------------------------------------

    # Log locally. The path is defined on `Settings.Path.logsDir`.
    # @param [String] logType The log type (info, warn, error, debug, etc).
    # @param [String] message Message to be logged.
    # @private
    logLocal: (logType, message) ->
        now = moment()
        message = now.format("HH:mm:ss.SSS") + " - " + message
        localBuffer[logType] = [] if not localBuffer[logType]?
        localBuffer[logType].push message

    # Flush all local buffered log messages to disk. This is usually called by the `bufferDispatcher` timer.
    flushLocal: ->
        return if flushing

        # Set flushing and current date.
        flushing = true
        now = moment()
        date = now.format "YYYYMMDD"

        # Flush all buffered logs to disk. Please note that messages from the last seconds of the previous day
        # can be saved to the current day depending on how long it takes for the bufferDispatcher to run.
        # Default is every 10 seconds, so messages from 23:59:50 onwards could be saved on the next day.
        for key, logs of localBuffer
            if logs.length > 0
                writeData = logs.join "\n"
                filePath = path.join settings.path.logsDir, "#{date}.#{key}.log"
                successMsg = "#{logs.length} records logged to disk."

                # Reset this local buffer.
                localBuffer[key] = []

                # Only use `appendFile` on new versions of Node.
                if fs.appendFile?
                    fs.appendFile filePath, writeData, (err) =>
                        flushing = false
                        if err?
                            console.error "LoggerLoggly.flushLocal", err
                            @onLogError err if @onLogError?
                        else
                            @onLogSuccess successMsg if @onLogSuccess?

                else
                    fs.open filePath, "a", 666, (err1, fd) =>
                        if err1?
                            flushing = false
                            console.error "LoggerLoggly.flushLocal.open", err1
                            @onLogError err1 if @onLogError?
                        else
                            fs.write fd, writeData, null, settings.general.encoding, (err2) =>
                                flushing = false
                                if err2?
                                    console.error "LoggerLoggly.flushLocal.write", err2
                                    @onLogError err2 if @onLogError?
                                else
                                    @onLogSuccess successMsg if @onLogSuccess?
                                fs.closeSync fd

    # Delete old log files from disk. The maximum date is defined on the settings.
    cleanLocal: ->
        maxDate = moment().subtract settings.logger.local.maxAge, "d"

        fs.readdir settings.path.logsDir, (err, files) ->
            if err?
                console.error "LoggerLoggly.cleanLocal", err
            else
                for f in files
                    date = moment f.split(".")[1], "yyyyMMdd"
                    if date.isBefore maxDate
                        fs.unlink path.join(settings.path.logsDir, f), (err) ->
                            console.error "LoggerLoggly.cleanLocal", err if err?

    # HELPER METHODS
    # --------------------------------------------------------------------------

    # Returns a human readable message out of the arguments.
    # @return [String] The human readable, parsed JSON message.
    # @private
    getMessage: ->
        separated = []
        args = arguments
        args = args[0] if args.length is 1

        # Parse all arguments and stringify objects. Please note that fields defined
        # on the `Settings.logger.removeFields` won't be added to the message.
        for a in args
            if settings.logger.removeFields.indexOf(a) < 0
                if lodash.isArray a
                    for b in a
                        separated.push b if settings.logger.removeFields.indexOf(b) < 0
                else if lodash.isObject a
                    try
                        separated.push JSON.stringify a
                    catch ex
                        separated.push a
                else
                    separated.push a

        # Append IP address, if `serverIP` is set.
        separated.push "IP #{serverIP}" if serverIP?

        # Return single string log message.
        return separated.join " | "

    # Wrapper callback for `onLogSuccess` and `onLogError` to be used by Loggly.
    # @param [String] err The Loggly error.
    # @param [String] result The Loggly logging result.
    # @private
    logglyCallback: (err, result) =>
        if err? and @onLogError?
            @onLogError err
        else if @onLogSuccess?
            @onLogSuccess result

# Singleton implementation
# --------------------------------------------------------------------------
LoggerLoggly.getInstance = ->
    @instance = new LoggerLoggly() if not @instance?
    return @instance

module.exports = exports = LoggerLoggly.getInstance()
