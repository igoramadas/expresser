# EXPRESSER SETTINGS
# -----------------------------------------------------------------------------
# All server settings for the app are set on this file. Settings can be overriden
# by creating a settings.json file with the specified keys and values.

class Settings

    # GENERAL
    # -------------------------------------------------------------------------
    General:
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
    Path:
        # Path to the email templates folder.
        emailTemplatesDir: "./emailtemplates/"
        # Path to the public folder used by Express.
        publicDir: "./public/"
        # Path where the .jade views are stored.
        viewsDir: "./views/"

    # WEB
    # -------------------------------------------------------------------------
    Web:
        # Secret key used for cookie encryption.
        cookieSecret: "ExpresserCookie"
        # Node.js server IP. Leaving blank or null will set the server to listen on all addresses.
        # This value might be overriden by PaaS environmental values.
        ip: null
        # Node.js server port. Please note that this value might be overriden by PaaS
        # environmental values (like in AppFog or OpenShift).
        port: 3456
        # Secret key used for session encryption.
        sessionSecret: "ExpresserSession"
        # The view engine used by Express. Default is jade.
        viewEngine: "jade"

    # CONNECT ASSETS
    # -------------------------------------------------------------------------
    ConnectAssets:
        # Build single assets?
        build: true
        # Build directories?
        buildDir: false
        # Minify JS and CSS builds?
        minifyBuilds: true

    # ERROR HANDLING
    # -------------------------------------------------------------------------
    ErrorHandling:
        # Dump exceptions? On production environments we recommend setting this to false.
        dumpExceptions: false
        # Show stack trace? On production environments we recommend setting this to false.
        showStack: false

    # DATABASE
    # ----------------------------------------------------------------------
    Database:
        # Connection string to MongoDB, using the format `user:password@hostname/dbname`.
        connString: null
        # In case you don't have failover / sharding in place on the database above
        # using MongoDB built-in features, you can set a failover connection string below.
        # It will be used ONLY if connection to the main database fails repeatedly.
        connString2: null
        # How long to wait before trying to connect to the main database again (in seconds).
        failoverTimeout: 300
        # How many retries before switching to the failover database or aborting a database operation.
        maxRetries: 3
        # Normalize documents ID (replace _id with id)?
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
    Email:
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
            # Connect using SSL? If you're using prt 587 then secure must be set to false in most cases.
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
            # Connect to secondary using SSL? If you're using prt 587 then secure must be set to false in most cases.
            secure: false
            # The secondary SMTP auth username.
            user: null

    # LOGGING
    # -------------------------------------------------------------------------
    # Built-in support for Loggly and Logentries.
    Log:
        # If `sendIP` is true, the IP address of the machine will be added to logs events.
        # Useful when you have different instances of the app running on different services.
        sendIP: true
        # If `sendTimestamp` is true, a timestamp will be added to logs events.
        # Please note that Loggly and Logentries already have a timestamp, so in most
        # cases you can leave this value set to false.
        sendTimestamp: false
        # Inform your Loggly subdomain and token. Loggly will be used ONLY if
        # the active setting below  is true.
        Loggly:
            active: false
            subdomain: null
            token: null
        # Please inform your Logentries token. Logentries will be used ONLY if
        # the active setting below  is true.
        Logentries:
            active: false
            token: null

    # LOGGING
    # -------------------------------------------------------------------------
    # Built-in support for New Relic. Will be used ONLY if the appName and licenseKey
    # settings below are set and valid.
    NewRelic:
        # The App Name on New Relic.
        appName: null
        # The License Key on New Relic.
        licenseKey: null

    # TWITTER
    # -------------------------------------------------------------------------
    # If you want to integrate with Twitter, you'll need to register an application
    # at http://dev.twitter.com and set the properties below.
    Twitter:
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


# Singleton implementation
# -----------------------------------------------------------------------------
Settings.getInstance = ->
    if not @instance?
        @instance = new Settings()

        fs = require "fs"
        filename = __dirname + "/settings.json"

        # If settings.json does not exist on root, try on local path.
        filename = "./settings.json" if not fs.existsSync filename

        # Check if there's a `settings.json` file, and overwrite settings if so.
        if fs.existsSync filename
            settingsJson = require filename

            # Helper function to overwrite settings.
            xtend = (source, target) ->
                for prop, value of source
                    if value?.constructor is Object
                        xtend source[prop], target[prop]
                    else
                        target[prop] = source[prop]

            xtend settingsJson, @instance

        # Set debug in case it has not been set.
        if not @instance.General.debug?
            if process.env.NODE_ENV is "production"
                @instance.General.debug = false
            else
                @instance.General.debug = true

    return @instance

module.exports = exports = Settings.getInstance()