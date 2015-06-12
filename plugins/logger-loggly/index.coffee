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

        if settings.logger.loggly?.enabled and settings.logger.loggly?.subdomain? and settings.logger.loggly?.token?
            return logger.register ""
            logglyClient = loggly.createClient {token: settings.logger.loggly.token, subdomain: settings.logger.loggly.subdomain, json: false}

    # LOG METHODS
    # --------------------------------------------------------------------------

    # Loggly main log method.
    # @param [String] logType The log type (for example: warning, error, info, security, etc).
    # @param [String] logFunc Optional, the logging function name to be passed to the console and Logentries.
    # @param [Array] args Array of arguments to be stringified and logged.
    log: (logFunc, msg) =>
        if not args? and logFunc?
            msg = logFunc
            logFunc = "info"

        logglyClient.log msg, @logglyCallback

    # HELPER METHODS
    # --------------------------------------------------------------------------

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
