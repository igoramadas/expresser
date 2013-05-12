# EXPRESSER LOGGER
# --------------------------------------------------------------------------
# Handles server logging using Logentries or Loggly. Please make sure to
# set the correct parameters on the (log settings)[settings.html].

class Logger

    lodash = require "lodash"
    settings = require "./settings.coffee"

    # Logging providers will be set on `init`.
    logentries = null
    loggly = null
    logger = null

    # The `serverIP` will be set on init, but only if `settings.Log.sendIP` is true.
    serverIP = null


    # INIT
    # --------------------------------------------------------------------------

    # Init the Logger. Verify which service is set, and add the necessary transports.
    # IP address and timestamp will be appended to logs depending on the [settings](settings.html).
    init: =>
        if settings.Log.sendIP
            ifaces = require("os").networkInterfaces()
            for i of ifaces
                ifaces[i].forEach (details) ->
                    if details.family is "IPv4" and not details.internal
                        serverIP = details.address

        if settings.Log.service is "loggly"
            logentries = null
            loggly = require "loggly"
            logger = loggly.createClient {subdomain: settings.Log.Loggly.subdomain, json: true}
        else
            loggly = null
            logentries = require "node-logentries"
            logger = logentries.logger {token: settings.Log.Logentries.token, timestamp: settings.Log.sendTimestamp}

        if serverIP?
            ipInfo = "IP #{serverIP}"
        else
            ipInfo = "No IP set."

        if settings.General.debug
            @info "LOGGING STARTED! (DEBUG MODE)", ipInfo
        else
            @info "LOGGING STARTED!", ipInfo


    # LOG METHODS
    # --------------------------------------------------------------------------

    # Log any object to the default transports as `log`.
    info: =>
        console.info.apply(this, arguments) if settings.General.debug
        msg = @getMessage arguments

        if loggly?
            logger.log.apply logger, msg
        else
            logger.info.apply logger, msg

    # Log any object to the default transports as `warn`.
    warn: =>
        console.warn.apply(this, arguments) if settings.General.debug
        msg = @getMessage arguments

        if loggly?
            logger.log.apply logger, msg
        else
            logger.warning.apply logger, msg

    # Log any object to the default transports as `error`.
    error: =>
        console.error.apply(this, arguments) if settings.General.debug
        msg = @getMessage arguments

        if loggly?
            logger.log.apply logger, msg
        else
            logger.err.apply logger, msg

    # Log security related info to the default transports as `warn`.
    security: =>
        console.warn.apply(this, arguments) if settings.General.debug
        msg = @getMessage arguments

        if loggly?
            logger.log.apply logger, msg
        else
            logger.warning.apply logger, msg


    # HELPER METHODS
    # --------------------------------------------------------------------------

    # Serializes the parameters and return a JSON object representing the log message,
    # depending on the service being used.
    getMessage: ->
        result = []
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

        # Loggly needs the token as first argument.
        if loggly?
            result.push(settings.Log.Loggly.token)
            result.push(separated.join " | ")
        else
            result.push(separated.join " | ")

        return result


# Singleton implementation
# --------------------------------------------------------------------------
Logger.getInstance = ->
    @instance = new Logger() if not @instance?
    return @instance

module.exports = exports = Logger.getInstance()