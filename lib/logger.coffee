# EXPRESSER LOGGER
# --------------------------------------------------------------------------
# Handles server logging using local files, Logentries or Loggly.
# Multiple services can be enabled at the same time.
# Parameters on settings.coffee: Settings.Logger

class Logger

    fs = require "fs"
    lodash = require "lodash"
    settings = require "./settings.coffee"

    # Logging providers will be set on `init`.
    local = null
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
        local = null
        logentries = null
        loggly = null
        serverIP = null
        activeServices = []

        # Get a valid server IP to be appended to logs.
        if settings.Logger.sendIP
            ifaces = require("os").networkInterfaces()
            for i of ifaces
                ifaces[i].forEach (details) ->
                    if details.family is "IPv4" and not details.internal
                        serverIP = details.address

        # Check if logs should be saved locally.
        if settings.Logger.Local.active
            if not fs.existsSync settings.Path.logsDir
                fs.mkdirSync settings.Path.logsDir
            local = true
            activeServices.push "Local"

        # Check if Loggly should be used.
        if settings.Logger.Logentries.active and settings.Logger.Logentries.token? and settings.Logger.Logentries.token isnt ""
            logentries = require "node-logentries"
            loggerLogentries = logentries.logger {token: settings.Logger.Logentries.token, timestamp: settings.Logger.sendTimestamp}
            activeServices.push "Logentries"

        # Check if Logentries should be used.
        if settings.Logger.Loggly.active and settings.Logger.Loggly.subdomain? and settings.Logger.Loggly.token? and settings.Logger.Loggly.token isnt ""
            loggly = require "loggly"
            loggerLoggly = loggly.createClient {subdomain: settings.Logger.Loggly.subdomain, json: true}
            activeServices.push "Loggly"

        # Define server IP.
        if serverIP?
            ipInfo = "IP #{serverIP}"
        else
            ipInfo = "No server IP set."

        # Start logging!
        if not local and not logentries? and not loggly?
            @warn "Expresser", "Logger.init", "Local, Logentries and Loggly are not enabled.", "Logger module will only log to the console!"
        else
            @info "Expresser", "Logger.init", activeServices.join(), ipInfo


    # LOG METHODS
    # --------------------------------------------------------------------------

    # Log any object to the default transports as `log`.
    info: =>
        console.info.apply(this, arguments) if settings.General.debug or activeServices.length < 1
        msg = @getMessage arguments

        if local
            @logLocal "info", msg
        if logentries?
            loggerLogentries.info.apply this, [msg]
        if loggly?
            loggerLoggly.log.apply this, [settings.Logger.Loggly.token, msg]

    # Log any object to the default transports as `warn`.
    warn: =>
        console.warn.apply(this, arguments) if settings.General.debug or activeServices.length < 1
        msg = @getMessage arguments

        if local
            @logLocal "warn", msg
        if logentries?
            loggerLogentries.warning.apply this, [msg]
        if loggly?
            loggerLoggly.log.apply this, [settings.Logger.Loggly.token, msg]

    # Log any object to the default transports as `error`.
    error: =>
        console.error.apply(this, arguments) if settings.General.debug or activeServices.length < 1
        msg = @getMessage arguments

        if local
            @logLocal "error", msg
        if logentries?
            loggerLogentries.err.apply this, [msg]
        if loggly?
            loggerLoggly.log.apply this, [settings.Logger.Loggly.token, msg]


    # HELPER METHODS
    # --------------------------------------------------------------------------

    # Log locally. The path is defined on `Settings.Path.logsDir`.
    logLocal: (logType, message) ->


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