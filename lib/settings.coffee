# EXPRESSER SETTINGS
# -----------------------------------------------------------------------------
# All server settings for the app are set on this file. Settings can be overriden
# by creating a `settings.json` file with the specified keys and values, for example:
# {
#   "general": {
#     "debug": true,
#     "appTitle": "A Super Cool App"
#   },
#   "firewall" {
#     "enabled": false
#   }
# }
#
# You can also create specific settings for different running environments.
# For example to set settings on development, create `settings.development.json`
# and for production a `settings.production.json` file. These will be parsed
# AFTER the main `settings.json` file. Lowercased!
#
# Please note that the `settings.json` must ne located on the root of your app!
#
# More info: https://expresser.codeplex.com/wikipage?title=Settings

class Settings

    fs = require "fs"

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
            # Minify JS and CSS builds? True or false. If left null, it will minify on
            # production environments but not on development.
            minifyBuilds: null

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
            # The LDAP admin dn. Example: cn=root.
            adminDn: null
            # The LDAP admin password. Example: mypass.
            adminPassword: null
            # The LDAP search base. Example: cn=users,dc=local.
            searchBase: null
            # The LDAP search filter. Example: (&(l=Berlin)(email=*@zalando.de)).
            searchFilter: null
            # The LDAP server full address with hostname and port. Example: ldap://127.0.0.1:1390.
            server: null

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
        # List will all field / property names to be removed from logs.
        # Default list is "Password, password, passwordHash and passwordEncrypted".
        removeFields: "Password,password,passwordHash,passwordEncrypted"
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
        # Save logs locally? The path to the logs folder is set above under the `path.logsDir` key.
        local:
            enabled: true
            # The bufferInterval defines the delay in between disk saves, in milliseconds.
            bufferInterval: 6000
            # Sets the max age of log files, in days. Default is 30 days. Setting the
            # maxAge to to 0 or null will cancel the automatic log cleaning.
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

    # DOWNLOADER
    # -------------------------------------------------------------------------
    # Built-in download manager.
    downloader:
        # Default headers to append to all download requests.
        # For example: {"Content-Type": "application/json"}
        headers: null
        # How many simultaneous downloads to allow?
        maxSimultaneous: 4
        # If true, the downloader will cancel duplicates. A duplicate is considered a download
        # from the same remote URL and the same save location.
        preventDuplicates: true
        # Reject unathourized requests (when SSL certificate has expired for example)?
        # Set this to true for increased security.
        rejectUnauthorized: false
        # The temp extension used while downloading files. Default is ".download".
        tempExtension: ".download"
        # Download timeout, in seconds.
        timeout: 3600

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
        # Enable the Twitter module?
        enabled: true
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


    # HELPER METHODS
    # -------------------------------------------------------------------------

    # Reset to default settings.
    reset:
        @instance = new Settings()


# Singleton implementation
# -----------------------------------------------------------------------------
Settings.getInstance = ->
    if not @instance?
        @instance = new Settings()

        # Set debug in case it has not been set.
        if not @instance.general.debug?
            if process.env.NODE_ENV is "development"
                @instance.general.debug = true
            else
                @instance.general.debug = false

        # Set minifyBuilds in case it has not been set.
        if not @instance.app.connectAssets.minifyBuilds?
            if process.env.NODE_ENV is "development"
                @instance.app.connectAssets.minifyBuilds = false
            else
                @instance.app.connectAssets.minifyBuilds = true

    return @instance

module.exports = exports = Settings.getInstance()