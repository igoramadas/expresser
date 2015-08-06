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

        if settings.logger.logentries.enabled and settings.logger.logentries.token? and settings.logger.logentries.token isnt ""
            loggerLogentries = logentries.logger {token: settings.logger.logentries.token, timestamp: settings.logger.sendTimestamp}
            loggerLogentries.on("log", logger.onLogSuccess) if lodash.isFunction @onLogSuccess
            loggerLogentries.on("error", logger.onLogError) if lodash.isFunction @onLogError
            logger.activeServices.push "Logentries"

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
        maxDate = moment().subtract settings.logger.local.maxAge, "d"

        fs.readdir settings.path.logsDir, (err, files) ->
            if err?
                console.error "Logger.cleanLocal", err
            else
                for f in files
                    date = moment f.split(".")[1], "yyyyMMdd"
                    if date.isBefore maxDate
                        fs.unlink path.join(settings.path.logsDir, f), (err) ->
                            console.error "Logger.cleanLocal", err if err?

# Singleton implementation
# --------------------------------------------------------------------------
LoggerLogentries.getInstance = ->
    @instance = new LoggerLogentries() if not @instance?
    return @instance

module.exports = exports = LoggerLogentries.getInstance()
