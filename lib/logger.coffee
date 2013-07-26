# EXPRESSER LOGGER
# --------------------------------------------------------------------------
# Handles server logging using local files, Logentries or Loggly.
# Multiple services can be enabled at the same time.
# Parameters on [settings.html](settings.coffee): Settings.Logger

class Logger

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

    # Holds a list of current active logging services.
    activeServices = []

    # Custom method to call when logs are sent / saved successfully. Please note that for local log
    # files whis will be called ONLY when logs are flushed to disk.
    onLogSuccess: null

    # Custom method to call when errors are triggered by the logging transport.
    onLogError: null


    # INIT AND STOP
    # --------------------------------------------------------------------------

    # Init the Logger. Verify which services are set, and add the necessary transports.
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
            serverIP = utils.getServerIP()

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
                    @error "Expresser", "Unhandled exception!", err.stack
                catch ex
                    console.error "Expresser", "Unhandled exception!", Date(Date.now()), err.stack, ex

        # Start logging!
        if not localBuffer? and not logentries? and not loggly?
            @warn "Expresser", "Logger.init", "No transports enabled.", "Logger module will only log to the console!"
        else
            @info "Expresser", "Logger.init", activeServices.join(), ipInfo

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

    # Log any object to the default transports as `log`.
    info: =>
        console.info.apply(this, arguments) if settings.logger.console
        msg = @getMessage arguments

        if localBuffer?
            @logLocal "info", msg
        if logentries?
            loggerLogentries.info.apply loggerLogentries, [msg]
        if loggly?
            loggerLoggly.log.apply loggerLoggly, [settings.logger.loggly.token, msg, @logglyCallback]

    # Log any object to the default transports as `warn`.
    warn: =>
        console.warn.apply(this, arguments) if settings.logger.console
        msg = @getMessage arguments

        if localBuffer?
            @logLocal "warn", msg
        if logentries?
            loggerLogentries.warning.apply loggerLogentries, [msg]
        if loggly?
            loggerLoggly.log.apply loggerLoggly, [settings.logger.loggly.token, msg, @logglyCallback]

    # Log any object to the default transports as `error`.
    error: =>
        console.error.apply(this, arguments) if settings.logger.console
        msg = @getMessage arguments

        if localBuffer?
            @logLocal "error", msg
        if logentries?
            loggerLogentries.err.apply loggerLogentries, [msg]
        if loggly?
            loggerLoggly.log.apply loggerLoggly, [settings.logger.loggly.token, msg, @logglyCallback]


    # LOCAL LOGGING
    # --------------------------------------------------------------------------

    # Log locally. The path is defined on `Settings.Path.logsDir`.
    logLocal: (logType, message) ->
        now = moment()
        message = now.format("HH:mm:ss.SSS") + " - " + message
        localBuffer[logType] = [] if not localBuffer[logType]?
        localBuffer[logType].push message

    # Flush all local buffered log messages to disk. This is usually called by the `bufferDispatcher` timer.
    flushLocal: ->
        return if flushing

        # Set flushing and current time.
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
                            console.error("Expresser", "Logger.flushLocal", err)
                            @onLogError err if @onLogError?
                        else
                            @onLogSuccess successMsg if @onLogSuccess?

                else
                    fs.open filePath, "a", 666, (err1, fd) =>
                        if err1?
                            flushing = false
                            console.error("Expresser", "Logger.flushLocal.open", err1)
                            @onLogError err1 if @onLogError?
                        else
                            fs.write fd, writeData, null, "utf8", (err2) =>
                                flushing = false
                                if err2?
                                    console.error("Expresser", "Logger.flushLocal.write", err2)
                                    @onLogError err2 if @onLogError?
                                else
                                    @onLogSuccess successMsg if @onLogSuccess?
                                fs.closeSync fd

    # Delete old log files.
    cleanLocal: ->
        maxDate = moment().subtract "d", settings.logger.local.maxAge

        fs.readdir settings.path.logsDir, (err, files) ->
            if err?
                console.error "Expresser", "Logger.cleanLocal", err
            else
                for f in files
                    date = moment f.split(".")[1], "yyyyMMdd"
                    if date.isBefore maxDate
                        fs.unlink path.join(settings.path.logsDir, f), (err) ->
                            console.error("Expresser", "Logger.cleanLocal", err) if err?


    # HELPER METHODS
    # --------------------------------------------------------------------------

    # Serializes the parameters and return a JSON object representing the log message,
    # depending on the service being used.
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