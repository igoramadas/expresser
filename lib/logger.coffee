# EXPRESSER LOGGER
# --------------------------------------------------------------------------
# Handles server logging using local files, Logentries or Loggly.
# Multiple services can be enabled at the same time.
# Parameters on [settings.html](settings.coffee): Settings.Logger

class Logger

    fs = require "fs"
    lodash = require "lodash"
    path = require "path"
    settings = require "./settings.coffee"
    utils = require "./utils.coffee"

    # Local logging objects will be set on `init`.
    bufferDispatcher = null
    localBuffer = null

    # Remote logging providers will be set on `init`.
    logentries = null
    loggly = null
    loggerLogentries = null
    loggerLoggly = null

    # The `serverIP` will be set on init, but only if `settings.logger.sendIP` is true.
    serverIP = null

    # Holds a list of current active logging services.
    activeServices = []


    # INIT
    # --------------------------------------------------------------------------

    # Init the Logger. Verify which services are set, and add the necessary transports.
    # IP address and timestamp will be appended to logs depending on the settings.
    init: =>
        if bufferDispatcher?
            @flushLocal()
            clearInterval bufferDispatcher

        bufferDispatcher = null
        localBuffer = null
        logentries = null
        loggly = null
        serverIP = null
        activeServices = []

        # Get a valid server IP to be appended to logs.
        if settings.logger.sendIP
            serverIP = utils.getServerIP()

        # Check if logs should be saved locally. If so, create the logs buffer and a timer to
        # flush logs to disk every X milliseconds.
        if settings.logger.local.enabled
            if not fs.existsSync settings.path.logsDir
                fs.mkdirSync settings.path.logsDir
            localBuffer = {info: [], warn: [], error: []}
            bufferDispatcher = setInterval @flushLocal, settings.logger.bufferInterval
            activeServices.push "Local"

        # Check if Logentries should be used, and create the Logentries objects.
        if settings.logger.logentries.enabled and settings.logger.logentries.token? and settings.logger.logentries.token isnt ""
            logentries = require "node-logentries"
            loggerLogentries = logentries.logger {token: settings.logger.logentries.token, timestamp: settings.logger.sendTimestamp}
            activeServices.push "Logentries"

        # Check if Loggly should be used, and create the Loggly objects.
        if settings.logger.loggly.enabled and settings.logger.loggly.subdomain? and settings.logger.loggly.token? and settings.logger.loggly.token isnt ""
            loggly = require "loggly"
            loggerLoggly = loggly.createClient {subdomain: settings.logger.loggly.subdomain, json: true}
            activeServices.push "Loggly"

        # Define server IP.
        if serverIP?
            ipInfo = "IP #{serverIP}"
        else
            ipInfo = "No server IP set."

        # Start logging!
        if not localBuffer? and not logentries? and not loggly?
            @warn "Expresser", "Logger.init", "Local, Logentries and Loggly are not enabled.", "Logger module will only log to the console!"
        else
            @info "Expresser", "Logger.init", activeServices.join(), ipInfo


    # LOG METHODS
    # --------------------------------------------------------------------------

    # Log any object to the default transports as `log`.
    info: =>
        console.info.apply(this, arguments) if settings.general.debug or activeServices.length < 1
        msg = @getMessage arguments

        if localBuffer?
            @logLocal "info", msg
        if logentries?
            loggerLogentries.info.apply this, [msg]
        if loggly?
            loggerLoggly.log.apply this, [settings.logger.loggly.token, msg]

    # Log any object to the default transports as `warn`.
    warn: =>
        console.warn.apply(this, arguments) if settings.general.debug or activeServices.length < 1
        msg = @getMessage arguments

        if localBuffer?
            @logLocal "warn", msg
        if logentries?
            loggerLogentries.warning.apply this, [msg]
        if loggly?
            loggerLoggly.log.apply this, [settings.logger.loggly.token, msg]

    # Log any object to the default transports as `error`.
    error: =>
        console.error.apply(this, arguments) if settings.general.debug or activeServices.length < 1
        msg = @getMessage arguments

        if localBuffer?
            @logLocal "error", msg
        if logentries?
            loggerLogentries.err.apply this, [msg]
        if loggly?
            loggerLoggly.log.apply this, [settings.logger.loggly.token, msg]


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
        now = moment()
        date = now.format "yyyyMMdd"

        # Flush all buffered logs to disk. Please note that messages from the last seconds of the previous day
        # can be saved to the current day depending on how long it takes for the bufferDispatcher to run.
        # Default is every 10 seconds, so messages from 23:59:50 onwards could be saved on the next day.
        for key, logs of localBuffer
            filePath = path.join settings.path.logsDir, "#{key}.#{date}.log"
            fs.appendFile filePath, logs.join("\n"), (err) ->
                console.error("Expresser", "Logger.flushLocal", err) if err?

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

        # Parse all arguments and stringify objects.
        for a in args
            if lodash.isArray a
                for b in a
                    separated.push b
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


# Singleton implementation
# --------------------------------------------------------------------------
Logger.getInstance = ->
    @instance = new Logger() if not @instance?
    return @instance

module.exports = exports = Logger.getInstance()