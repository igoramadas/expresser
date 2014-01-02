# EXPRESSER UTILS
# -----------------------------------------------------------------------------
# General network, IO, client and server utilities. As this module can't reference
# any other module but Settings, all its logging will be done to the console only.
class Utils

    crypto = require "crypto"
    fs = require "fs"
    lodash = require "lodash"
    moment = require "moment"
    os = require "os"
    path = require "path"
    settings = require "./settings.coffee"

    # SETTINGS UTILS
    # --------------------------------------------------------------------------

    # Helper to encrypt or decrypt settings files. The default encryption password
    # defined on the `Settings.coffee` file is "ExpresserSettings". The default
    # cipher algorithm is AES 256.
    # @param [Boolean] encrypt Pass true to encrypt, false to decrypt.
    # @param [String] filename The file to be encrypted or decrypted.
    # @param [Object] options Options to be passed to the cipher.
    # @option options [String] cipher The cipher to be used, default is aes256.
    # @option options [String] password The default encryption password.
    settingsJsonCryptoHelper: (encrypt, filename, options) =>
        options = {} if not options?
        options = lodash.defaults options, {cipher: "aes256", password: settings.general.settingsSecret}

        settingsJson = @loadSettingsFromJson filename, false

        # Settings file not found or invalid? Stop here.
        if not settingsJson? and settings.logger.console
            console.warn "Utils.settingsJsonCryptoHelper", encrypt, filename, "File not found or invalid, abort!"
            return false

        # If trying to encrypt and settings property `encrypted` is true,
        # abort encryption and log to the console.
        if settingsJson.encrypted is true and encrypt
            if settings.logger.console
                console.warn "Utils.settingsJsonCryptoHelper", encrypt, filename, "Property 'encrypted' is true, abort!"
                return false

        # Helper to parse and encrypt / decrypt settings data.
        parser = (obj) ->
            for prop, value of obj
                if value?.constructor is Object
                    parser obj[prop]
                else
                    try
                        currentValue = obj[prop]

                        if encrypt

                            # Check the property data type and prefix the new value.
                            if lodash.isBoolean currentValue
                                newValue = "bool:"
                            else if lodash.isNumber currentValue
                                newValue = "number:"
                            else
                                newValue = "string:"

                            # Create cipher amd encrypt data.
                            c = aes = crypto.createCipher options.cipher, options.password
                            newValue += c.update currentValue.toString(), settings.general.encoding, "hex"
                            newValue += c.final "hex"

                        else

                            # Split the data as "datatype:encryptedValue".
                            arrValue = currentValue.split ":"
                            newValue = ""

                            # Create cipher and decrypt.
                            c = aes = crypto.createDecipher options.cipher, options.password
                            newValue += c.update arrValue[1], "hex", settings.general.encoding
                            newValue += c.final settings.general.encoding

                            # Cast data type (boolean, number or string).
                            if arrValue[0] is "bool"
                                if newValue is "true" or newValue is "1"
                                    newValue = true
                                else
                                    newValue = false
                            else if arrValue[0] is "number"
                                newValue = parseFloat newValue
                    catch ex
                        if settings.logger.console
                            console.error "Utils.settingsJsonCryptoHelper", encrypt, filename, ex, currentValue

                    # Update settings property value.
                    obj[prop] = newValue

        # Remove `encrypted` property prior to decrypting.
        if not encrypt
            delete settingsJson["encrypted"]

        # Process settings data.
        parser settingsJson

        # Add `encrypted` property after file is encrypted.
        if encrypt
            settingsJson.encrypted = true

        # Stringify and save the new settings file.
        newSettingsJson = JSON.stringify settingsJson, null, 4
        fs.writeFileSync filename, newSettingsJson, {encoding: settings.general.encoding}
        return true

    # Helper to encrypt the specified settings file. Please see `settingsJsonCryptoHelper` above.
    # @param [String] filename The file to be encrypted.
    # @param [Object] options Options to be passed to the cipher.
    # @return [Boolean] Returns true if encryption OK, false if something went wrong.
    encryptSettingsJson: (filename, options) =>
        @settingsJsonCryptoHelper true, filename, options

    # Helper to decrypt the specified settings file. Please see `settingsJsonCryptoHelper` above.
    # @param [String] filename The file to be decrypted.
    # @param [Object] options Options to be passed to the cipher.
    # @return [Boolean] Returns true if decryption OK, false if something went wrong.
    decryptSettingsJson: (filename, options) =>
        @settingsJsonCryptoHelper false, filename, options

    # Helper to load default `settings.json` and `settings.NODE_ENV.json` files.
    loadDefaultSettingsFromJson: =>
        currentEnv = process.env.NODE_ENV
        currentEnv = "development" if not currentEnv? or currentEnv is ""
        @loadSettingsFromJson "settings.json"
        @loadSettingsFromJson "settings.#{currentEnv.toString().toLowerCase()}.json"

    # Helper to load values from the specified settings file. If `doNotUpdateSettings` is
    # true it won't update the `Settings` class with the loaded data. This is useful when
    # you want to pre-process the data before update the `Settings` class.
    # @param [String] filename The filename or path to the settings file.
    # @param [Boolean] doNotUpdateSettings If true it won't update the Settings class, default is false.
    # @return [Object] Returns the JSON representation of the loaded file.
    loadSettingsFromJson: (filename, doNotUpdateSettings) =>
        filename = @getConfigFilePath filename
        settingsJson = null

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
            # Executed only if `doNotUpdateSettings` is not true.
            if not doNotUpdateSettings
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

        # Return the JSON representation of the file (or null if not found / empty).
        return settingsJson

    # Update settings based on Cloud Environmental variables. If a `filter` is specified,
    # update only settings that match it, otherwise update everything.
    # @param [String] filter Filter settings to be updated, for example "mailer" or "database".
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

        # Update mailer settings (SendGrid, Mandrill, Mailgun).
        if not filter or filter.indexOf("mail") >= 0
            currentSmtpHost = settings.mailer.smtp.host?.toLowerCase()
            currentSmtpHost = "" if not currentSmtpHost?

            # Get and set SendGrid.
            smtpUser = env.SENDGRID_USERNAME
            smtpPassword = env.SENDGRID_PASSWORD
            if currentSmtpHost.indexOf("sendgrid") >= 0
                if currentSmtpHost is "sendgrid"
                    settings.mailer.smtp.host = "smtp.sendgrid.net"
                    settings.mailer.smtp.port = 587
                    settings.mailer.smtp.secure = false
                if smtpUser? and smtpUser isnt "" and smtpPassword? and smtpPassword isnt ""
                    settings.mailer.smtp.user = smtpUser
                    settings.mailer.smtp.password = smtpPassword

            # Get and set Mandrill.
            smtpUser = env.MANDRILL_USERNAME
            smtpPassword = env.MANDRILL_APIKEY
            if currentSmtpHost.indexOf("mandrill") >= 0
                if currentSmtpHost is "mandrill"
                    settings.mailer.smtp.host = "smtp.mandrillapp.com"
                    settings.mailer.smtp.port = 587
                    settings.mailer.smtp.secure = false
                if smtpUser? and smtpUser isnt "" and smtpPassword? and smtpPassword isnt ""
                    settings.mailer.smtp.user = smtpUser
                    settings.mailer.smtp.password = smtpPassword

            # Get and set Mailgun.
            smtpHost = env.MAILGUN_SMTP_SERVER
            smtpPort = env.MAILGUN_SMTP_PORT
            smtpUser = env.MAILGUN_SMTP_LOGIN
            smtpPassword = env.MAILGUN_SMTP_PASSWORD
            if currentSmtpHost.indexOf("mailgun") >= 0
                if smtpHost? and smtpHost isnt "" and smtpPort? and smtpPort isnt ""
                    settings.mailer.smtp.host = smtpHost
                    settings.mailer.smtp.port = smtpPort
                else if currentSmtpHost is "mailgun"
                    settings.mailer.smtp.host = "smtp.mailgun.org"
                    settings.mailer.smtp.port = 587
                    settings.mailer.smtp.secure = false
                if smtpUser? and smtpUser isnt "" and smtpPassword? and smtpPassword isnt ""
                    settings.mailer.smtp.user = smtpUser
                    settings.mailer.smtp.password = smtpPassword

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

    # Enable or disable the settings files watcher to auto reload settings when file changes.
    # The `callback` is optional in case you want to notify another module about settings updates.
    # @param [Boolean] enable If enabled is true activate the fs watcher, otherwise deactivate.
    # @param [Method] callback A function (event, filename) triggered when a settings file changes.
    watchSettingsFiles: (enable, callback) =>
        currentEnv = process.env.NODE_ENV
        currentEnv = "development" if not currentEnv? or currentEnv is ""

        # Make sure callback is a function, if pased.
        if callback? and not lodash.isFunction callback
            throw new TypeError "The callback must be a valid function, or null/undefined."

        # Add / remove watcher for the settings.json file if it exists.
        filename = @getConfigFilePath "settings.json"
        if filename?
            if enable
                fs.watchFile filename, {persistent: true}, (evt, filename) =>
                    @loadSettingsFromJson filename
                    callback(evt, filename) if callback?
            else
                fs.unwatchFile filename, callback

        # Add / remove watcher for the settings.node_env.json file if it exists.
        filename = @getConfigFilePath "settings.#{currentEnv.toString().toLowerCase()}.json"
        if filename?
            if enable
                fs.watchFile filename, {persistent: true}, (evt, filename) =>
                    @loadSettingsFromJson filename
                    callback(evt, filename) if callback?
            else
                fs.unwatchFile filename, callback

        if settings.general.debug and settings.logger.console
            console.log "Utils.watchSettingsFiles", enable, (if callback? then "With callback" else "No callback")


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

    # Returns a list of valid server IP addresses. If `firstOnly` is true it will
    # return only the very first IP address found.
    # @param [Boolean] firstOnly Optional, default is false which returns an array with all valid IPs, true returns a String will first valid IP.
    # @return The server IPv4 address, or null.
    getServerIP: (firstOnly) ->
        ifaces = os.networkInterfaces()
        result = []

        # Parse network interfaces and try getting the server IPv4 address.
        for i of ifaces
            ifaces[i].forEach (details) ->
                if details.family is "IPv4" and not details.internal
                    result.push details.address

        # Return only first IP or all of them?
        if firstOnly
            return result[0]
        else
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