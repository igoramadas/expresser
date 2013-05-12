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
    loggerLogentries = null
    loggerLoggly = null

    # The `serverIP` will be set on init, but only if `settings.Log.sendIP` is true.
    serverIP = null


    # INIT
    # --------------------------------------------------------------------------

    # Init the Logger. Verify which service is set, and add the necessary transports.
    # IP address and timestamp will be appended to logs depending on the [settings](settings.html).
    init: =>
        services = []

        if settings.Log.sendIP
            ifaces = require("os").networkInterfaces()
            for i of ifaces
                ifaces[i].forEach (details) ->
                    if details.family is "IPv4" and not details.internal
                        serverIP = details.address

        # Check if Loggly should be used.
        if settings.Log.Logentries.token? and settings.Log.Logentries.token isnt ""
            logentries = require "node-logentries"
            loggerLogentries = logentries.logger {token: settings.Log.Logentries.token, timestamp: settings.Log.sendTimestamp}
            services.push "Logentries"

        # Check if Logentries should be used.
        if settings.Log.Loggly.subdomain? and settings.Log.Loggly.token? and settings.Log.Loggly.token isnt ""
            loggly = require "loggly"
            loggerLoggly = loggly.createClient {subdomain: settings.Log.Loggly.subdomain, json: true}
            services.push "Loggly"

        # Define server IP.
        if serverIP?
            ipInfo = "IP #{serverIP}"
        else
            ipInfo = "No IP set."

        # Start logging!
        if not logentries? and not loggly?
            @warn "Expresser", "Logger.init", "Logentries and Loggly credentials were not set.", "Logger module won't work!"
        else
            @info "Expresser", "Logger.init", services.join()


    # LOG METHODS
    # --------------------------------------------------------------------------

    # Log any object to the default transports as `log`.
    info: =>
        console.info.apply(this, arguments) if settings.General.debug
        msg = @getMessage arguments

        if logentries?
            loggerLogentries.info.apply this, [msg]
        if loggly?
            loggerLoggly.log.apply this, [settings.Log.Loggly.token, msg]

    # Log any object to the default transports as `warn`.
    warn: =>
        console.warn.apply(this, arguments) if settings.General.debug
        msg = @getMessage arguments

        if logentries?
            loggerLogentries.warning.apply this, [msg]
        if loggly?
            loggerLoggly.log.apply this, [settings.Log.Loggly.token, msg]

    # Log any object to the default transports as `error`.
    error: =>
        console.error.apply(this, arguments) if settings.General.debug
        msg = @getMessage arguments

        if logentries?
            loggerLogentries.err.apply this, [msg]
        if loggly?
            loggerLoggly.log.apply this, [settings.Log.Loggly.token, msg]


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