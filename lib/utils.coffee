# EXPRESSER UTILS
# -----------------------------------------------------------------------------
# General network, IO, client and server utilities. As this module can't reference
# any other module but Settings, all its logging will be done to the console only.
class Utils

    fs = require "fs"
    moment = require "moment"
    os = require "os"
    path = require "path"
    settings = require "./settings.coffee"

    # The settings watcher object.
    settingsWatchers = []


    # SETTINGS UTILS
    # --------------------------------------------------------------------------

    # Enable or disable the settings files watcher to auto reload settings when file changes.
    # The `callback` is optional in case you want to notify another module.
    # @param [Boolean] enable If enabled is true activate the fs watcher, otherwise deactivate.
    # @param [Method] callback A function (event, filename) triggered when a settings file changes.
    watchSettingsFiles: (enable, callback) =>
        currentEnv = process.env.NODE_ENV
        currentEnv = "development" if not currentEnv? or currentEnv is ""

        # Stop current watchers and reset the `settingsWatchers` array.
        w.close() for w in settingsWatchers
        settingsWatchers = []

        # If `enable` is true, proceed enabling the watchers.
        if enable

            # Add watcher for the settings.json file if it exists.
            filename = @getConfigFilePath "settings.json"
            if filename?
                watcher = fs.watch filename, {persistent: true}, (evt, filename) =>
                    @loadSettingsFromJson filename
                    callback(evt, filename) if callback?
                settingsWatchers.push watcher

            # Add watcher for the settings.node_env.json file if it exists.
            filename = @getConfigFilePath "settings.#{currentEnv.toString().toLowerCase()}.json"
            if filename?
                watcher = fs.watch filename, {persistent: true}, (evt, filename) =>
                    @loadSettingsFromJson filename
                    callback(evt, filename) if callback?
                settingsWatchers.push watcher

    # Helper to load default `settings.json` files. This will also load the specific
    # settings for the current NODE_ENV value.
    loadDefaultSettingsFromJson: =>
        @loadSettingsFromJson "settings.json"
        currentEnv = process.env.NODE_ENV
        currentEnv = "development" if not currentEnv? or currentEnv is ""
        @loadSettingsFromJson "settings.#{currentEnv.toString().toLowerCase()}.json"

    # Helper to load values from the specified settings file.
    # @param [String] filename The filename or path to the settings file.
    loadSettingsFromJson: (filename) =>
        filename = @getConfigFilePath filename

        # Has json? Load it. Try using UTF8 first, if failed, use ASCII.
        if filename?
            if process.versions.node.indexOf(".10.") > 0
                try
                    settingsJson = fs.readFileSync filename, {encoding: settings.general.encoding}
                catch ex
                    settingsJson = fs.readFileSync filename, {encoding: "ascii"}
            else
                try
                    settingsJson = fs.readFileSync filename, settings.general.encoding
                catch ex
                    settingsJson = fs.readFileSync filename, "ascii"

            # Parse the JSON file.
            settingsJson = @minifyJson settingsJson

            # Helper function to overwrite settings.
            xtend = (source, target) ->
                for prop, value of source
                    if value?.constructor is Object
                        target[prop] = {} if not target[prop]?
                        xtend source[prop], target[prop]
                    else
                        target[prop] = source[prop]

            xtend settingsJson, settings

        if settings.general.debug and settings.logger.console
            console.log "Utils.loadSettingsFromJson", filename

    # Update settings based on Cloud Environmental variables. If a `filter` is specified,
    # update only settings that match it, otherwise update everything.
    # @param [String] filter Filter settings to be updated, for example "mail" or "database".
    updateSettingsFromPaaS: (filter) =>
        env = process.env
        filter = false if not filter? or filter is ""

        # Update app IP and port (OpenShift, AppFog).
        if not filter or filter.indexOf("app") >= 0
            ip = env.OPENSHIFT_NODEJS_IP or env.IP
            port = env.OPENSHIFT_NODEJS_PORT or env.VCAP_APP_PORT or env.PORT
            settings.app.ip = ip if ip? and ip isnt ""
            settings.app.port = port if port? and port isnt ""

        # Update database settings (AppFog, MongoLab, MongoHQ).
        if not filter or filter.indexOf("database") >= 0
            vcap = env.VCAP_SERVICES
            vcap = JSON.parse vcap if vcap?

            # Check for AppFog MongoDB variables.
            if vcap? and vcap isnt ""
                mongo = vcap["mongodb-1.8"]
                mongo = mongo[0]["credentials"] if mongo?
                if mongo?
                    settings.database.connString = "mongodb://#{mongo.hostname}:#{mongo.port}/#{mongo.db}"

            # Check for MongoLab variables.
            mongoLab = env.MONGOLAB_URI
            settings.database.connString = mongoLab if mongoLab? and mongoLab isnt ""

            # Check for MongoHQ variables.
            mongoHq = env.MONGOHQ_URL
            settings.database.connString = mongoHq if mongoHq? and mongoHq isnt ""

        # Update logger settings (Logentries and Loggly).
        if not filter or filter.indexOf("logger") >= 0
            logentriesToken = env.LOGENTRIES_TOKEN
            logglyToken = env.LOGGLY_TOKEN
            logglySubdomain = env.LOGGLY_SUBDOMAIN
            settings.logger.logentries.token = logentriesToken if logentriesToken? and logentriesToken isnt ""
            settings.logger.loggly.token = logglyToken if logglyToken? and logglyToken isnt ""
            settings.logger.loggly.subdomain = logglySubdomain if logglySubdomain? and logglySubdomain isnt ""

        # Update mail settings (SendGrid, Mandrill, Mailgun).
        if not filter or filter.indexOf("mail") >= 0
            currentSmtpHost = settings.mail.smtp.host?.toLowerCase()
            currentSmtpHost = "" if not currentSmtpHost?

            # Get and set SendGrid.
            smtpUser = env.SENDGRID_USERNAME
            smtpPassword = env.SENDGRID_PASSWORD
            if currentSmtpHost.indexOf("sendgrid") >= 0
                if currentSmtpHost is "sendgrid"
                    settings.mail.smtp.host = "smtp.sendgrid.net"
                    settings.mail.smtp.port = 587
                    settings.mail.smtp.secure = false
                if smtpUser? and smtpUser isnt "" and smtpPassword? and smtpPassword isnt ""
                    settings.mail.smtp.user = smtpUser
                    settings.mail.smtp.password = smtpPassword

            # Get and set Mandrill.
            smtpUser = env.MANDRILL_USERNAME
            smtpPassword = env.MANDRILL_APIKEY
            if currentSmtpHost.indexOf("mandrill") >= 0
                if currentSmtpHost is "mandrill"
                    settings.mail.smtp.host = "smtp.mandrillapp.com"
                    settings.mail.smtp.port = 587
                    settings.mail.smtp.secure = false
                if smtpUser? and smtpUser isnt "" and smtpPassword? and smtpPassword isnt ""
                    settings.mail.smtp.user = smtpUser
                    settings.mail.smtp.password = smtpPassword

            # Get and set Mailgun.
            smtpHost = env.MAILGUN_SMTP_SERVER
            smtpPort = env.MAILGUN_SMTP_PORT
            smtpUser = env.MAILGUN_SMTP_LOGIN
            smtpPassword = env.MAILGUN_SMTP_PASSWORD
            if currentSmtpHost.indexOf("mailgun") >= 0
                if smtpHost? and smtpHost isnt "" and smtpPort? and smtpPort isnt ""
                    settings.mail.smtp.host = smtpHost
                    settings.mail.smtp.port = smtpPort
                else if currentSmtpHost is "mailgun"
                    settings.mail.smtp.host = "smtp.mailgun.org"
                    settings.mail.smtp.port = 587
                    settings.mail.smtp.secure = false
                if smtpUser? and smtpUser isnt "" and smtpPassword? and smtpPassword isnt ""
                    settings.mail.smtp.user = smtpUser
                    settings.mail.smtp.password = smtpPassword

        # Update twitter settings.
        if not filter or filter.indexOf("twitter") >= 0
            twitterConsumerKey = env.TWITTER_CONSUMER_KEY
            twitterConsumerSecret = env.TWITTER_CONSUMER_SECRET
            twitterAccessKey = env.TWITTER_ACCESS_KEY
            twitterAccessSecret = env.TWITTER_ACCESS_SECRET
            settings.twitter.consumerKey = twitterConsumerKey if twitterConsumerKey? and twitterConsumerKey isnt ""
            settings.twitter.consumerSecret = twitterConsumerSecret if twitterConsumerSecret? and twitterConsumerSecret isnt ""
            settings.twitter.accessToken = twitterAccessKey if twitterAccessKey? and twitterAccessKey isnt ""
            settings.twitter.accessSecret = twitterAccessSecret if twitterAccessSecret? and twitterAccessSecret isnt ""

        # Log to console.
        if settings.general.debug and settings.logger.console
            console.log "Utils.updateSettingsFromPaaS", "Settings updated"


    # SERVER INFO UTILS
    # --------------------------------------------------------------------------

    # Helper to get the correct filename for general config files. For example
    # the settings.json file or cron.json for cron jobs. This will look into the current
    # directory, the running directory and the root directory of the app.
    # @param [String] filename The base filename (with extension) of the config file.
    # @return [String] The full path to the config file if one was found, or null.
    getConfigFilePath: (filename) ->
        basename = path.basename filename

        # Get correct exists function.
        if fs.existsSync?
            exists = fs.existsSync
        else
            exists = path.existsSync

        # Check if file exists.
        hasJson = exists filename
        return filename if hasJson

        # If file does not exist on local path, try parent path.
        filename = path.resolve path.dirname(require.main.filename), "../#{basename}"
        hasJson = exists filename
        return filename if hasJson

        # If file still not found, try root path.
        filename = path.resolve __dirname, basename
        hasJson = exists filename
        return filename if hasJson

        # Nothing found, so return null.
        return null

    # Returns the first valid server IPv4 address.
    # @return The server IPv4 address, or null.
    getServerIP: ->
        ifaces = os.networkInterfaces()
        result = null

        # Parse network interfaces and try getting the server IPv4 address.
        for i of ifaces
            ifaces[i].forEach (details) ->
                if details.family is "IPv4" and not details.internal
                    result = details.address

        return result

    # Return an object with general information about the server.
    # @return [Object] Results with process pid, platform, memory, uptime and IP.
    getServerInfo: =>
        result = {}

        # Parse server info.
        pid = process.pid + " " + process.title
        platform = process.platform + " " + process.arch + ", v" + process.version
        memUsage = process.memoryUsage()
        memUsage = Math.round(memUsage.headUsed / 1000) + " / " + Math.round(memUsage.heapTotal / 1000) + " MB"
        uptime = moment.duration(process.uptime, "s").humanize()

        # Save parsed info to the result object.
        result.pid = pid
        result.platform = platform
        result.memoryUsage = memUsage
        result.uptime = uptime
        result.ip = @getServerIP()

        return result


    # CLIENT INFO UTILS
    # --------------------------------------------------------------------------

    # Get the client or browser IP. Works for http and socket requests, even when behind a proxy.
    # @param [Object] reqOrSocket The request or socket object.
    # @return [String] The client IP address, or null.
    getClientIP: (reqOrSocket) ->
        return null if not reqOrSocket?

        # Try getting the xforwarded header first.
        if reqOrSocket.header?
            xfor = reqOrSocket.header "X-Forwarded-For"
            if xfor? and xfor isnt ""
                return xfor.split(",")[0]

        # Get remote address.
        if reqOrSocket.connection?
            return reqOrSocket.connection.remoteAddress
        else
            return reqOrSocket.remoteAddress

    # Get the client's device. This identifier string is based on the user agent.
    # @param [Object] req The request object.
    # @return [String] The client's device.
    getClientDevice: (req) ->
        ua = req.headers["user-agent"]

        # Find mobile devices.
        return "mobile-wp-8" if ua.indexOf("Windows Phone 8") > 0
        return "mobile-wp-7" if ua.indexOf("Windows Phone 7") > 0
        return "mobile-wp" if ua.indexOf("Windows Phone") > 0
        return "mobile-iphone-5" if ua.indexOf("iPhone5") > 0
        return "mobile-iphone-4" if ua.indexOf("iPhone4") > 0
        return "mobile-iphone" if ua.indexOf("iPhone") > 0
        return "mobile-android-5" if ua.indexOf("Android 5") > 0
        return "mobile-android-4" if ua.indexOf("Android 4") > 0
        return "mobile-android" if ua.indexOf("Android") > 0

        # Find desktop browsers.
        return "desktop-chrome" if ua.indexOf("Chrome/") > 0
        return "desktop-firefox" if ua.indexOf("Firefox/") > 0
        return "desktop-safari" if ua.indexOf("Safari/") > 0
        return "desktop-opera" if ua.indexOf("Opera/") > 0
        return "desktop-ie-11" if ua.indexOf("MSIE 11") > 0
        return "desktop-ie-10" if ua.indexOf("MSIE 10") > 0
        return "desktop-ie-9" if ua.indexOf("MSIE 9") > 0
        return "desktop-ie" if ua.indexOf("MSIE") > 0

        # Return default desktop value if no specific devices were found on user agent.
        return "desktop"


    # DATA UTILS
    # --------------------------------------------------------------------------

    # Minify the passed JSON value. Removes comments, unecessary white spaces etc.
    # @param [String] source The JSON text to be minified.
    # @param [Boolean] asString If true, return as string instead of JSON object.
    # @return [String] The minified JSON, or an empty string if there's an error.
    minifyJson: (source, asString) ->
        source = JSON.stringify source if typeof source is "object"
        index = 0
        length = source.length
        result = ""
        symbol = undefined
        position = undefined

        # Main iterator.
        while index < length

            symbol = source.charAt(index)
            switch symbol

                # Ignore whitespace tokens. According to ES 5.1 section 15.12.1.1,
                # whitespace tokens include tabs, carriage returns, line feeds, and
                # space characters.
                when "\t", "\r"
                , "\n"
                , " "
                    index += 1

                # Ignore line and block comments.
                when "/"
                    symbol = source.charAt(index += 1)
                    switch symbol

                        # Line comments.
                        when "/"
                            position = source.indexOf("\n", index)

                            # Check for CR-style line endings.
                            position = source.indexOf("\r", index)  if position < 0
                            index = (if position > -1 then position else length)

                        # Block comments.
                        when "*"
                            position = source.indexOf("*/", index)
                            if position > -1

                                # Advance the scanner's position past the end of the comment.
                                index = position += 2
                                break
                            throw SyntaxError("Unterminated block comment.")
                        else
                            throw SyntaxError("Invalid comment.")

                # Parse strings separately to ensure that any whitespace characters and
                # JavaScript-style comments within them are preserved.
                when "\""
                    position = index
                    while index < length
                        symbol = source.charAt(index += 1)
                        if symbol is "\\"

                            # Skip past escaped characters.
                            index += 1
                        else break  if symbol is "\""
                    if source.charAt(index) is "\""
                        result += source.slice(position, index += 1)
                        break
                    throw SyntaxError("Unterminated string.")

                # Preserve all other characters.
                else
                    result += symbol
                    index += 1

        # Check if should return as string or JSON.
        if asString
            return result
        else
            return JSON.parse result


# Singleton implementation
# --------------------------------------------------------------------------
Utils.getInstance = ->
    @instance = new Utils() if not @instance?
    return @instance

module.exports = exports = Utils.getInstance()