# EXPRESSER LOGGER - FILE
# -----------------------------------------------------------------------------
fs = require "fs"
path = require "path"

errors = null
events = null
lodash = null
logger = null
moment = null
settings = null

###
# File logging plugin for Expresser. Supports saving directly to the disk
# using one file per log type per day, and includes auto cleaning features.
###
class LoggerFile
    priority: 1

    # INIT
    # -------------------------------------------------------------------------

    ###
    # Init the File logging module. If default settings are defined on "settings.logger.file",
    # it will auto register itself to the main Logger as "file". Please note that this init
    # should be called automatically by the main Expresser `init()`.
    # @private
    ###
    init: =>
        errors = @expresser.errors
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        moment = @expresser.libs.moment
        settings = @expresser.settings

        logger.drivers.file = this

        logger.debug "LoggerFile.init"

        # Auto register as "file" if a default path is defined on the settings.
        if settings.logger.file.enabled and settings.logger.file.path?
            logger.register "file", "file", settings.logger.file

        events.emit "LoggerFile.on.init"
        delete @init

    ###
    # Get the File transport object.
    # @param {Object} options File logging options.
    # @param {String} [options.path] Path where log files should be saved, mandatory.
    # @param {Function} [options.onLogSuccess] Function to execute on successful log calls, optional.
    # @param {Function} [options.onLogError] Function to execute on failed log calls, optional.
    # @return {Object} The File logger transport.
    ###
    getTransport: (options) ->
        logger.debug "LoggerFile.getTransport", options

        if not settings.logger.file.enabled
            return logger.notEnabled "LoggerFile"

        if not options?.path? or options.path is ""
            return errors.throw pathRequired, "Please set a valid options.path."

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
    # -------------------------------------------------------------------------

    ###
    # Log locally. The path is defined on `settings.logger.file.path`.
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

        # Set log props and send to buffer.
        now = moment()
        message = now.format("HH:mm:ss.SSS") + " - " + message

        @buffer[logType] = [] if not @buffer[logType]?
        @buffer[logType].push message

        # Log to the console depending on `console` setting.
        if settings.logger.console and not avoidConsole
            logger.console logType, args

    # PERSISTENCE
    # -------------------------------------------------------------------------

    ###
    # Flush all local buffered log messages to disk. This is automatically called
    # by the `bufferDispatcher` timer but you can also trigger it manually.
    ###
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

    ###
    # Delete old log files from disk.
    # @param {Number} maxAge Max age of logs, in days, default is defined on settings.
    ###
    clean: (maxAge) ->
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
# -----------------------------------------------------------------------------
LoggerFile.getInstance = ->
    @instance = new LoggerFile() if not @instance?
    return @instance

module.exports = exports = LoggerFile.getInstance()
