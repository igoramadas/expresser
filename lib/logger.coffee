# EXPRESSER LOGGER
# --------------------------------------------------------------------------
# Handles server logging using Logentries or Loggly.
# Parameters on settings.coffee: Settings.Log

class Logger

    lodash = require "lodash"
    settings = require "./settings.coffee"

    # Logging providers will be set on `init`.
    logentries = null
    loggly = null
    loggerLogentries = null
    loggerLoggly = null

    # The `serverIP` will be set on init, but only if `settings.Logger.sendIP` is true.
    serverIP = null

    # Holds a list of current active logging services.
    activeServices = []


    # INIT
    # --------------------------------------------------------------------------

    # Init the Logger. Verify which services are set, and add the necessary transports.
    # IP address and timestamp will be appended to logs depending on the settings.
    init: =>
        if settings.Logger.sendIP
            ifaces = require("os").networkInterfaces()
            for i of ifaces
                ifaces[i].forEach (details) ->
                    if details.family is "IPv4" and not details.internal
                        serverIP = details.address

        # Check if Loggly should be used.
        if settings.Logger.Logentries.token? and settings.Logger.Logentries.token isnt ""
            logentries = require "node-logentries"
            loggerLogentries = logentries.logger {token: settings.Logger.Logentries.token, timestamp: settings.Logger.sendTimestamp}
            activeServices.push "Logentries"

        # Check if Logentries should be used.
        if settings.Logger.Loggly.subdomain? and settings.Logger.Loggly.token? and settings.Logger.Loggly.token isnt ""
            loggly = require "loggly"
            loggerLoggly = loggly.createClient {subdomain: settings.Logger.Loggly.subdomain, json: true}
            activeServices.push "Loggly"

        # Define server IP.
        if serverIP?
            ipInfo = "IP #{serverIP}"
        else
            ipInfo = "No IP set."

        # Start logging!
        if not logentries? and not loggly?
            @warn "Expresser", "Logger.init", "Logentries and Loggly credentials were not set.", "Logger module won't work!"
        else
            @info "Expresser", "Logger.init", activeServices.join(), ipInfo


    # LOG METHODS
    # --------------------------------------------------------------------------

    # Log any object to the default transports as `log`.
    info: =>
        console.info.apply(this, arguments) if settings.General.debug or activeServices.length < 1
        msg = @getMessage arguments

        if logentries?
            loggerLogentries.info.apply this, [msg]
        if loggly?
            loggerLoggly.log.apply this, [settings.Logger.Loggly.token, msg]

    # Log any object to the default transports as `warn`.
    warn: =>
        console.warn.apply(this, arguments) if settings.General.debug or activeServices.length < 1
        msg = @getMessage arguments

        if logentries?
            loggerLogentries.warning.apply this, [msg]
        if loggly?
            loggerLoggly.log.apply this, [settings.Logger.Loggly.token, msg]

    # Log any object to the default transports as `error`.
    error: =>
        console.error.apply(this, arguments) if settings.General.debug or activeServices.length < 1
        msg = @getMessage arguments

        if logentries?
            loggerLogentries.err.apply this, [msg]
        if loggly?
            loggerLoggly.log.apply this, [settings.Logger.Loggly.token, msg]


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