# EXPRESSER SETTINGS
# -----------------------------------------------------------------------------
# All server settings for the app are set on this file. Settings can be overriden
# by creating a settings.json file with the specified keys and values, for example:
# {
#   "General": {
#     "debug": true,
#     "appTitle": "A Super Cool App"
#   },
#   "Firewall" {
#     "enabled": false
#   }
# }
# Please note that the settings.json must ne located on the root of your app!

fs = require "fs"
path = require "path"

class Settings

    # GENERAL
    # -------------------------------------------------------------------------
    general:
        # Enable or disable debugging messages. Should be false on production environments.
        # If null, debug will be set automatically based on the NODE_ENV variable.
        debug: null
        # The app title. This MUST be set.
        appTitle: "Expresser"
        # The app's base URL, including http://. This MUST be set.
        appUrl: "http://expresser.codeplex.com"
        # How long (seconds) should files read from disk (email templates for example) stay in cache?
        ioCacheTimeout: 60

    # PATHS
    # -------------------------------------------------------------------------
    path:
        # Path to the email templates folder.
        emailTemplatesDir: "./emailtemplates/"
        # Path to local logs folder.
        logsDir: "./logs/"
        # Path to the public folder used by Express.
        publicDir: "./public/"
        # Path where the .jade views are stored.
        viewsDir: "./views/"

    # WEB
    # -------------------------------------------------------------------------
    app:
        # Secret key used for cookie encryption.
        cookieSecret: "ExpresserCookie"
        # Node.js server IP. Leaving blank or null will set the server to listen on all addresses.
        # This value might be overriden by PaaS environmental values.
        ip: null
        # If paas is true, Expresser will figure out some settings out of environment variables
        # like IP, ports and tokens. Leave true if you're deploying to AppFog, Heroku, OpenShift etc.
        paas: true
        # Node.js server port. Please note that this value might be overriden by PaaS
        # environmental values (like in AppFog or OpenShift).
        port: 8080
        # Secret key used for session encryption.
        sessionSecret: "ExpresserSession"
        # The view engine used by Express. Default is jade.
        viewEngine: "jade"
        # Connect Assets options.
        connectAssets:
            # Build single assets?
            build: true
            # Build directories?
            buildDir: false
            # Minify JS and CSS builds?
            minifyBuilds: true

    # PASSPORT MODULE
    # -------------------------------------------------------------------------
    passport:
        # Enable passport module on the App?
        enabled: false
        # Basic HTTP Auth strategy settings.
        basic:
            # Enable basic HTTP authentication?
            enabled: false
        # LDAP authentication strategy settings.
        ldap:
            # Enable LDAP authentication?
            enabled: false
            # The LDAP server full address with hostname and port. Example: ldap://127.0.0.1:1390.
            server: null
            # The LDAP base. Example: cn=users,dc=local.
            base: null
            # The LDAP search filter. Example: (&(l=Berlin)(email=*@zalando.de)).
            filter: null


    # SOCKETS
    # -------------------------------------------------------------------------
    sockets:
        # Enable the sockets helper?
        enabled: true

    # FIREWALL
    # -------------------------------------------------------------------------
    firewall:
        # How long should IP be blacklisted, in seconds.
        blacklistExpires: 30
        # How long should IP be blacklisted in case it reaches the "MaxRetries" value
        # below after being already blacklisted before?
        blacklistLongExpires: 3600
        # If a blacklisted IP keeps attacking, how many attacks till its expiry date
        # extends to the "LongExpires" value above?
        blacklistMaxRetries: 5
        # If enabled, all requests will be checked against common attacks.
        enabled: true
        # Which HTTP protection patterns should be enabled? Available: lfi, sql, xss
        httpPatterns: "lfi,sql,xss"
        # Which Socket protection patterns should be enabled? Available: lfi, sql, xss
        socketPatterns: "lfi,sql,xss"

    # DATABASE
    # ----------------------------------------------------------------------
    database:
        # Connection string to MongoDB, using the format `user:password@hostname/dbname`.
        connString: null
        # In case you don't have failover / sharding in place on the database above
        # using MongoDB built-in features, you can set a failover connection string below.
        # It will be used ONLY if connection to the main database fails repeatedly.
        connString2: null
        # How long to wait before trying to connect to the main database again (in seconds) in case
        # the module switches to the secondary one.
        failoverTimeout: 300
        # How many retries before switching to the failover database or aborting a database operation.
        maxRetries: 3
        # Normalize documents ID (replace _id with id when returning documents)?
        normalizeId: true
        # How long between connection retries, in milliseconds. Default is 5 seconds.
        retryInterval: 5000
        # Database connection options.
        options:
            # Auto recconect if connection is lost?
            autoReconnect: true
            # Default pool size for connections.
            poolSize: 8
            # Safe writes? Setting this to true makes sure that Mongo aknowledges disk writes.
            safe: false

    # EMAIL
    # -------------------------------------------------------------------------
    mail:
        # Default `from` email address.
        from: null
        # Main SMTP server.
        smtp:
            # The SMTP host. If set to null or blank, no emails will be sent out.
            host: null
            # The SMTP auth password.
            password: null
            # The SMTP port to connect to.
            port: null
            # Connect using SSL? If you're using port 587 then secure must be set to false in most cases.
            secure: false
            # The SMTP auth username.
            user: null
        # Secondary SMTP server. Will be used only if the main SMTP fails.
        smtp2:
            # The secondary SMTP host. If set to null or blank, no emails will be sent out.
            host: null
            # The secondary SMTP auth password.
            password: null
            # The secondary SMTP port to connect to.
            port: null
            # Connect to secondary using SSL? If you're using port 587 then secure must be set to false in most cases.
            secure: false
            # The secondary SMTP auth username.
            user: null

    # LOGGING
    # -------------------------------------------------------------------------
    # Built-in support for Loggly and Logentries.
    logger:
        # If `sendIP` is true, the IP address of the machine will be added to logs events.
        # Useful when you have different instances of the app running on different services.
        sendIP: true
        # If `sendTimestamp` is true, a timestamp will be added to logs events.
        # Please note that Loggly and Logentries already have a timestamp, so in most
        # cases you can leave this value set to false.
        sendTimestamp: false
        # Set `uncaughtException` to true to bind the logger to the `uncaughtException`
        # event on the process and log all uncaught expcetions as errors.
        uncaughtException: true
        # Save logs locally? The path to the logs folder is set above under the `Settings.Path.logsDir` key.
        local:
            enabled: false
            # The bufferInterval defines the delay in between disk saves, in milliseconds.
            bufferInterval: 10000
            # The maxAge sets the max age of log files, in days.
            maxAge: 30
        # Please inform your Logentries token. Logentries will be used ONLY if
        # the enabled setting below  is true.
        logentries:
            enabled: false
            token: null
        # Inform your Loggly subdomain and token. Loggly will be used ONLY if
        # the enabled setting below  is true.
        loggly:
            enabled: false
            subdomain: null
            token: null

    # NEW RELIC PROFILING
    # -------------------------------------------------------------------------
    # Built-in support for New Relic. Will be used ONLY if the appName and licenseKey
    # settings below are set and valid.
    newRelic:
        # The App Name on New Relic.
        appName: null
        # The License Key on New Relic.
        licenseKey: null

    # TWITTER
    # -------------------------------------------------------------------------
    # If you want to integrate with Twitter, you'll need to register an application
    # at http://dev.twitter.com and set the properties below.
    twitter:
        # Your OAuth access secret. This can be generated automatically for your
        # account on you application details page.
        accessSecret: null
        # Your OAuth access token. This can be generated automatically for your
        # account on you application details page.
        accessToken: null
        # The Twitter app consumer key.
        consumerKey: null
        # The Twitter app consumer secret.
        consumerSecret: null
        # How long to wait before trying to authenticate on Twitter again (in seconds),
        # in case the authentication fails.
        retryInterval: 600


    # SETTINGS.JSON
    # -------------------------------------------------------------------------

    # Helper to load values from the specified settings.json file.
    loadFromJson: (filename) =>
        settingsJson = require filename

        # Helper function to overwrite settings.
        xtend = (source, target) ->
            for prop, value of source
                if value?.constructor is Object
                    target[prop] = {} if not target[prop]?
                    xtend source[prop], target[prop]
                else
                    target[prop] = source[prop]

        xtend settingsJson, this


# Singleton implementation
# -----------------------------------------------------------------------------
Settings.getInstance = ->
    if not @instance?
        @instance = new Settings()

        # Load from server root.
        filename =  path.dirname(require.main.filename) + "/settings.json"
        if fs.existsSync?
            hasJson = fs.existsSync filename
        else
            hasJson = path.existsSync filename

        # If `settings.json` does not exist on root, try on local path.
        if not hasJson
            filename = __dirname + "/settings.json"
        if fs.existsSync?
            hasJson = fs.existsSync filename
        else
            hasJson = path.existsSync filename

        # Has json? Load it.
        if hasJson
            @instance.loadFromJson filename

        # Set debug in case it has not been set.
        if not @instance.general.debug?
            if process.env.NODE_ENV is "production"
                @instance.general.debug = false
            else
                @instance.general.debug = true

    return @instance

module.exports = exports = Settings.getInstance()