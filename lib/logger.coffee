# EXPRESSER LOGGER
# --------------------------------------------------------------------------
# Handles server logging using local files, Logentries or Loggly.
# Multiple services can be enabled at the same time.
# <!--
# @see Settings.logger
# -->
class Logger

    events = require "./events.coffee"
    fs = require "fs"
    lodash = require "lodash"
    moment = require "moment"
    path = require "path"
    settings = require "./settings.coffee"
    utils = require "./utils.coffee"

    # Local logging objects will be set on `init`.
    bufferDispatcher = null
    localBuffer = null
    flushing = false

    # Remote logging providers will be set on `init`.
    logentries = null
    loggly = null
    loggerLogentries = null
    loggerLoggly = null

    # The `serverIP` will be set on init, but only if `settings.logger.sendIP` is true.
    serverIP = null

    # Timer used for automatic logs cleaning.
    timerCleanLocal = null

    # @property [Method] Custom method to call when logs are sent to logging server or flushed to disk.
    onLogSuccess: null

    # @property [Method] Custom method to call when errors are triggered by the logging transport.
    onLogError: null

    # @property [Array] Holds a list of current active logging services.
    # @private
    activeServices = []


    # INIT AND STOP
    # --------------------------------------------------------------------------

    # Init the Logger module. Verify which services are set, and add the necessary transports.
    # IP address and timestamp will be appended to logs depending on the settings.
    init: =>
        bufferDispatcher = null
        localBuffer = null
        logentries = null
        loggly = null
        serverIP = null
        activeServices = []

        # Get a valid server IP to be appended to logs.
        if settings.logger.sendIP
            serverIP = utils.getServerIP true

        # Define server IP.
        if serverIP?
            ipInfo = "IP #{serverIP}"
        else
            ipInfo = "No server IP set."

        # Init transports.
        @initLocal()
        @initLogentries()
        @initLoggly()

        # Check if uncaught exceptions should be logged. If so, try logging unhandled
        # exceptions using the logger, otherwise log to the console.
        if settings.logger.uncaughtException
            process.on "uncaughtException", (err) ->
                try
                    @error "Unhandled exception!", err.stack
                catch ex
                    console.error "Unhandled exception!", Date(Date.now()), err.stack, ex

        # Start logging!
        if not localBuffer? and not logentries? and not loggly?
            @warn "Logger.init", "No transports enabled.", "Logger module will only log to the console!"
        else
            @info "Logger.init", activeServices.join(), ipInfo

    # Init the Local transport. Check if logs should be saved locally. If so, create the logs buffer
    # and a timer to flush logs to disk every X milliseconds.
    initLocal: =>
        if settings.logger.local.enabled
            if fs.existsSync?
                folderExists = fs.existsSync settings.path.logsDir
            else
                folderExists = path.existsSync settings.path.logsDir

            # Create logs folder, if it doesn't exist.
            if not folderExists
                fs.mkdirSync settings.path.logsDir
                if settings.general.debug
                    console.log "Logger.initLocal", "Created #{settings.path.logsDir} folder."

            # Set local buffer.
            localBuffer = {info: [], warn: [], error: []}
            bufferDispatcher = setInterval @flushLocal, settings.logger.local.bufferInterval
            activeServices.push "Local"

            # Check the maxAge of local logs.
            if settings.logger.local.maxAge? and settings.logger.local.maxAge > 0
                if timerCleanLocal?
                    clearInterval timerCleanLocal
                timerCleanLocal = setInterval @cleanLocal, 86400
        else
            @stopLocal()

    # Init the Logentries transport. Check if Logentries should be used, and create the Logentries objects.
    initLogentries: =>
        if settings.logger.logentries.enabled and settings.logger.logentries.token? and settings.logger.logentries.token isnt ""
            logentries = require "node-logentries"
            loggerLogentries = logentries.logger {token: settings.logger.logentries.token, timestamp: settings.logger.sendTimestamp}
            loggerLogentries.on("log", @onLogSuccess) if lodash.isFunction @onLogSuccess
            loggerLogentries.on("error", @onLogError) if lodash.isFunction @onLogError
            activeServices.push "Logentries"
        else
            @stopLogentries()

    # Init the Loggly transport. Check if Loggly should be used, and create the Loggly objects.
    initLoggly: =>
        if settings.logger.loggly.enabled and settings.logger.loggly.subdomain? and settings.logger.loggly.token? and settings.logger.loggly.token isnt ""
            loggly = require "loggly"
            loggerLoggly = loggly.createClient {subdomain: settings.logger.loggly.subdomain, json: false}
            activeServices.push "Loggly"
        else
            @stopLoggly()

    # Disable and remove Local transport from the list of active services.
    stopLocal: =>
        @flushLocal()
        clearInterval bufferDispatcher if bufferDispatcher?
        bufferDispatcher = null
        localBuffer = null
        i = activeServices.indexOf "Local"
        activeServices.splice(i, 1) if i >= 0

    # Disable and remove Logentries transport from the list of active services.
    stopLogentries: =>
        logentries = null
        loggerLogentries = null
        i = activeServices.indexOf "Logentries"
        activeServices.splice(i, 1) if i >= 0

    # Disable and remove Loggly transport from the list of active services.
    stopLoggly: =>
        loggly = null
        loggerLoggly = null
        i = activeServices.indexOf "Loggly"
        activeServices.splice(i, 1) if i >= 0


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

        # Log to the console depending on `console` setting.
        if settings.logger.console
            if settings.logger.errorLogTypes.indexOf(logType) >= 0
                console.error.apply this, args
            else
                console.log.apply this, args

        # Get message out of the arguments.
        msg = @getMessage args

        # Log to different transports.
        if settings.logger.local.enabled and localBuffer?
            @logLocal logType, msg
        if settings.logger.logentries.enabled and logentries?
            loggerLogentries.log logFunc, msg
        if settings.logger.loggly.enabled and loggly?
            loggerLoggly.log settings.logger.loggly.token, msg, @logglyCallback


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
        args = Array.prototype.slice.call arguments
        args.unshift "INFO"
        @log "info", "info", args

    # Log to the active transports as `warn`.
    # All arguments are transformed to readable strings.
    warn: =>
        args = Array.prototype.slice.call arguments
        args.unshift "WARN"
        @log "warn", "warn", args

    # Log to the active transports as `error`.
    # All arguments are transformed to readable strings.
    error: =>
        args = Array.prototype.slice.call arguments
        args.unshift "ERROR"
        @log "error", "err", args

    # Log to the active transports as `critical`.
    # All arguments are transformed to readable strings.
    critical: =>
        args = Array.prototype.slice.call arguments
        args.unshift "CRITICAL"
        @log "critical", "info", args

        # If the `criticalEmailTo` is set, dispatch a mail send event.
        if settings.logger.criticalEmailTo? and settings.logger.criticalEmailTo isnt ""
            mailOptions =
                subject: "CRITICAL: #{args[1]}"
                body: JSON.stringify args
                to: settings.logger.criticalEmailTo
                logError: false

            console.warn mailOptions

            events.emit "mailer.send", mailOptions, (err) ->
                console.error "Logger.critical", "Can't send email!", err if err?

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
                writeData = logs.join("\n")
                filePath = path.join settings.path.logsDir, "#{date}.#{key}.log"
                successMsg = "#{logs.length} records logged to disk."

                # Reset this local buffer.
                localBuffer[key] = []

                # Only use `appendFile` on new versions of Node.
                if fs.appendFile?
                    fs.appendFile filePath, writeData, (err) =>
                        flushing = false
                        if err?
                            console.error "Logger.flushLocal", err
                            @onLogError err if @onLogError?
                        else
                            @onLogSuccess successMsg if @onLogSuccess?

                else
                    fs.open filePath, "a", 666, (err1, fd) =>
                        if err1?
                            flushing = false
                            console.error "Logger.flushLocal.open", err1
                            @onLogError err1 if @onLogError?
                        else
                            fs.write fd, writeData, null, settings.general.encoding, (err2) =>
                                flushing = false
                                if err2?
                                    console.error "Logger.flushLocal.write", err2
                                    @onLogError err2 if @onLogError?
                                else
                                    @onLogSuccess successMsg if @onLogSuccess?
                                fs.closeSync fd

    # Delete old log files from disk. The maximum date is defined on the settings.
    cleanLocal: ->
        maxDate = moment().subtract "d", settings.logger.local.maxAge

        fs.readdir settings.path.logsDir, (err, files) ->
            if err?
                console.error "Logger.cleanLocal", err
            else
                for f in files
                    date = moment f.split(".")[1], "yyyyMMdd"
                    if date.isBefore maxDate
                        fs.unlink path.join(settings.path.logsDir, f), (err) ->
                            console.error "Logger.cleanLocal", err if err?

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
Logger.getInstance = ->
    @instance = new Logger() if not @instance?
    return @instance

module.exports = exports = Logger.getInstance()