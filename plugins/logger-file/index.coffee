# EXPRESSER LOGGER - FILE
# --------------------------------------------------------------------------
# File logging plugin for Expresser. Supports saving directly to the disk
# using one file per log type per day, and includes auto cleaning features.
# <!--
# @see settings.logger.file
# -->
class LoggerFile

    events = null
    fs = require "fs"
    lodash = null
    logger = null
    moment = null
    path = require "path"
    settings = null

    # INIT
    # --------------------------------------------------------------------------

    # Init the File module. Verify which services are set, and add the necessary transports.
    # IP address and timestamp will be appended to logs depending on the settings.
    # @param {Object} options File init options.
    init: =>
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        moment = @expresser.libs.moment
        settings = @expresser.settings

        logger.drivers.file = this

        # Auto register as "file" if a default path is defined on the settings.
        if settings.logger.file.enabled and settings.logger.file.path?
            result = logger.register "file", "file", settings.logger.file

        events.emit "LoggerFile.on.init"
        delete @init

        return result

    # Get the file transport object.
    # @param {Object} options File logging options.
    getTransport: (options) =>
        if not options?.path? or options.path is ""
            err = new Error "The options.path is mandatory! Please specify a valid path to the logs folder."
            logger.error "LoggerFile.getTransport", err, options
            throw err

        options = lodash.defaultsDeep options, settings.logger.file
        options.onLogSuccess = logger.onLogSuccess if not options.onLogSuccess?
        options.onLogError = logger.onLogError if not options.onLogError?

        # Create logs folder if it doesn't exist.
        folderExists = fs.existsSync options.path

        # Make sure the log folder exists.
        if not folderExists
            fs.mkdirSync options.path
            if settings.general.debug
                console.log "LoggerFile.getTransport", "Created #{options.path} folder."

        # Set local buffer.
        transport = {flushing: false, buffer: {}, flush: @flush, clean: @clean}
        transport.onLogSuccess = options.onLogSuccess
        transport.onLogError = options.onLogError
        transport.bufferDispatcher = setInterval transport.flush, options.bufferInterval

        # Check the maxAge of local logs and set up auto clean.
        if options.maxAge? and options.maxAge > 0
            transport.timerCleanLocal = setInterval transport.clean, options.bufferInterval * 20

        return transport

    # LOG METHODS
    # --------------------------------------------------------------------------

    # Log locally. The path is defined on `Settings.Path.logsDir`.
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

        # Set log props and send to buffer.
        now = moment()
        message = now.format("HH:mm:ss.SSS") + " - " + message

        @buffer[logType] = [] if not @buffer[logType]?
        @buffer[logType].push message

        # Log to the console depending on `console` setting.
        if settings.logger.console and not avoidConsole
            logger.console logType, args

    # Flush all local buffered log messages to disk. This is usually called by the `bufferDispatcher` timer.
    flush: ->
        return if @flushing

        # Set flushing and get current date.
        @flushing = true
        now = moment()
        date = now.format settings.logger.file.dateFormat

        # Flush all buffered logs to disk. Please note that messages from the last seconds of the previous day
        # can be saved to the current day depending on how long it takes for the bufferDispatcher to run.
        # Default is every 10 seconds, so messages from 23:59:50 onwards could be saved on the next day.
        for key, logs of @buffer
            if logs.length > 0
                writeData = logs.join "\n"
                filePath = path.join settings.logger.file.path, "#{date}.#{key}.log"
                successMsg = "#{logs.length} records logged to disk."

                # Reset this local buffer.
                @buffer[key] = []

                # Only use `appendFile` on new versions of Node.
                if fs.appendFile?
                    fs.appendFile filePath, "\n" + writeData, (err) =>
                        @flushing = false

                        if err?
                            console.error "LoggerFile.flush", err
                            @onLogError? err
                        else
                            @onLogSuccess? successMsg

                        events.emit "LoggerFile.on.flush", this

    # Delete old log files from disk. The maximum date is taken from the settings
    # if not passed.
    # @param {Integer} maxAge Max age of logs, in days.
    clean: (maxAge) =>
        maxAge = settings.logger.file.maxAge if not maxAge?
        maxDate = moment().subtract maxAge, "d"

        fs.readdir settings.logger.file.path, (err, files) =>
            if err?
                console.error "LoggerFile.clean", err
            else
                for f in files
                    date = moment f.split(".")[0], settings.logger.file.dateFormat
                    if date.isSameOrBefore maxDate
                        fs.unlinkSync path.join(settings.logger.file.path, f)

                events.emit "LoggerFile.on.clean", this, maxAge

# Singleton implementation
# --------------------------------------------------------------------------
LoggerFile.getInstance = ->
    @instance = new LoggerFile() if not @instance?
    return @instance

module.exports = exports = LoggerFile.getInstance()
