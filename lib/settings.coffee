# EXPRESSER SETTINGS
# -----------------------------------------------------------------------------
# All main settings for the Expresser platform are set and described on the
# settings.default.json file. Do not edit it!!! To change settings please
# create a settings.json file and put your values there.
#
# You can also create specific settings for different runtime environments.
# For example to set settings on development, create `settings.development.json`
# and for production a `settings.production.json` file. These will be parsed
# AFTER the main `settings.json` file.
#
# Please note that the `settings.json` must ne located on the root of your app!
# <!--
# @example Sample settings.json file
#   {
#     "general": {
#       "debug": true,
#       "appTitle": "A Super Cool App"
#     },
#     "firewall" {
#       "enabled": false
#     }
#   }
# -->
class Settings

    crypto = require "crypto"
    fs = require "fs"
    lodash = require "lodash"
    path = require "path"
    utils = require "./utils.coffee"

    currentEnv: process.env.NODE_ENV

    # MAIN METHODS
    # --------------------------------------------------------------------------

    # Load settings from settings.default.json, then settings.json, then environment specific settings.
    load: =>
        @currentEnv = process.env.NODE_ENV or "development"

        @loadFromJson "settings.default.json"
        @loadFromJson "settings.json"
        @loadFromJson "settings.#{@currentEnv.toString().toLowerCase()}.json"

    # Helper to load values from the specified settings file.
    # @param [String] filename The filename or path to the settings file.
    # @param [Boolean] doNotUpdateSettings If true it won't update the Settings class, default is false.
    # @return [Object] Returns the JSON representation of the loaded file.
    loadFromJson: (filename) =>
        filename = utils.getFilePath filename
        settingsJson = null

        # Has json? Load it. Try using UTF8 first, if failed, use ASCII.
        if filename?
            if process.versions.node.indexOf(".10.") > 0
                encUtf8 = {encoding: "utf8"}
                encAscii = {encoding: "ascii"}
            else
                encUtf8 = "utf8"
                encAscii = "ascii"

            # Try parsing the file with UTF8 first, if fails, try ASCII.
            try
                settingsJson = fs.readFileSync filename, encUtf8
                settingsJson = utils.minifyJson settingsJson
            catch ex
                settingsJson = fs.readFileSync filename, encAscii
                settingsJson = utils.minifyJson settingsJson

            # Helper function to overwrite properties.
            xtend = (source, target) ->
                for prop, value of source
                    if value?.constructor is Object
                        target[prop] = {} if not target[prop]?
                        xtend source[prop], target[prop]
                    else
                        target[prop] = source[prop]

            xtend settingsJson, this

        if @general.debug and @logger.console
            console.log "Settings.loadFromJson", filename

        # Return the JSON representation of the file (or null if not found / empty).
        return settingsJson

    # Reset to default settings.
    reset: =>
        @instance = new Settings()
        @instance.load()

    # ENCRYPTION
    # --------------------------------------------------------------------------

    # Helper to encrypt or decrypt settings files. The default encryption password
    # defined on the `Settings.coffee` file is "ExpresserSettings", which ideally you
    # should change. The default cipher algorithm is AES 256.
    # @param [Boolean] encrypt Pass true to encrypt, false to decrypt.
    # @param [String] filename The file to be encrypted or decrypted.
    # @param [Object] options Options to be passed to the cipher.
    # @option options [String] cipher The cipher to be used, default is aes256.
    # @option options [String] password The default encryption password.
    cryptoHelper: (encrypt, filename, options) =>
        options = {} if not options?
        options = lodash.defaults options, {cipher: "aes256", password: "ExpresserSettings"}

        settingsJson = @loadFromJson filename, false

        # Settings file not found or invalid? Stop here.
        if not settingsJson? and @logger.console
            console.warn "Settings.cryptoHelper", encrypt, filename, "File not found or invalid, abort!"
            return false

        # If trying to encrypt and settings property `encrypted` is true,
        # abort encryption and log to the console.
        if settingsJson.encrypted is true and encrypt
            if @logger.console
                console.warn "Settings.cryptoHelper", encrypt, filename, "Property 'encrypted' is true, abort!"
                return false

        # Helper to parse and encrypt / decrypt settings data.
        parser = (obj) =>
            currentValue = null

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
                            c = crypto.createCipher options.cipher, options.password
                            newValue += c.update currentValue.toString(), @general.encoding, "hex"
                            newValue += c.final "hex"

                        else

                            # Split the data as "datatype:encryptedValue".
                            arrValue = currentValue.split ":"
                            newValue = ""

                            # Create cipher and decrypt.
                            c = crypto.createDecipher options.cipher, options.password
                            newValue += c.update arrValue[1], "hex", @general.encoding
                            newValue += c.final @general.encoding

                            # Cast data type (boolean, number or string).
                            if arrValue[0] is "bool"
                                if newValue is "true" or newValue is "1"
                                    newValue = true
                                else
                                    newValue = false
                            else if arrValue[0] is "number"
                                newValue = parseFloat newValue
                    catch ex
                        if @logger.console
                            console.error "Settings.cryptoHelper", encrypt, filename, ex, currentValue

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
        if process.versions.node.indexOf(".10.") > 0
            fs.writeFileSync filename, newSettingsJson, {encoding: @general.encoding}
        else
            fs.writeFileSync filename, newSettingsJson, @general.encoding
        return true

    # Helper to encrypt the specified settings file. Please see `cryptoHelper` above.
    # @param [String] filename The file to be encrypted.
    # @param [Object] options Options to be passed to the cipher.
    # @return [Boolean] Returns true if encryption OK, false if something went wrong.
    encrypt: (filename, options) =>
        @cryptoHelper true, filename, options

    # Helper to decrypt the specified settings file. Please see `cryptoHelper` above.
    # @param [String] filename The file to be decrypted.
    # @param [Object] options Options to be passed to the cipher.
    # @return [Boolean] Returns true if decryption OK, false if something went wrong.
    decrypt: (filename, options) =>
        @cryptoHelper false, filename, options

    # FILE WATCHER
    # --------------------------------------------------------------------------

    # Enable or disable the settings files watcher to auto reload settings when file changes.
    # The `callback` is optional in case you want to notify another module about settings updates.
    # @param [Boolean] enable If enabled is true activate the fs watcher, otherwise deactivate.
    # @param [Method] callback A function (event, filename) triggered when a settings file changes.
    watch: (enable, callback) =>
        if callback? and not lodash.isFunction callback
            throw new TypeError "The callback must be a valid function, or null/undefined."

        logToConsole = @general.debug and @logger.console

        # Add / remove watcher for the @json file if it exists.
        filename = utils.getFilePath "settings.json"
        if filename?
            if enable
                fs.watchFile filename, {persistent: true}, (evt, filename) =>
                    @loadFromJson filename
                    console.log "Settings.watch", filename, "Reloaded!" if logToConsole
                    callback(evt, filename) if callback?
            else
                fs.unwatchFile filename, callback

        # Add / remove watcher for the settings.NODE_ENV.json file if it exists.
        filename = utils.getFilePath "settings.#{@currentEnv.toString().toLowerCase()}.json"
        if filename?
            if enable
                fs.watchFile filename, {persistent: true}, (evt, filename) =>
                    @loadFromJson filename
                    console.log "Settings.watch", filename, "Reloaded!" if logToConsole
                    callback(evt, filename) if callback?
            else
                fs.unwatchFile filename, callback

        if logToConsole
            console.log "Settings.watch", enable, (if callback? then "With callback" else "No callback")

    # PAAS
    # --------------------------------------------------------------------------

    # Update settings based on Cloud Environmental variables. If a `filter` is specified,
    # update only settings that match it, otherwise update everything.
    # @param [String] filter Filter settings to be updated, for example "mailer" or "database".
    updateFromPaaS: (filter) =>
        env = process.env
        filter = false if not filter? or filter is ""

        # Update app IP and port (OpenShift, AppFog).
        if not filter or filter.indexOf("app") >= 0
            ip = env.OPENSHIFT_NODEJS_IP or env.IP
            port = env.OPENSHIFT_NODEJS_PORT or env.VCAP_APP_PORT or env.PORT
            @app.ip = ip if ip? and ip isnt ""
            @app.port = port if port? and port isnt ""

        # Update database settings (AppFog, MongoLab, MongoHQ).
        if not filter or filter.indexOf("database") >= 0
            vcap = env.VCAP_SERVICES
            vcap = JSON.parse vcap if vcap?

            # Check for AppFog MongoDB variables.
            if vcap? and vcap isnt ""
                mongo = vcap["mongodb-1.8"]
                mongo = mongo[0]["credentials"] if mongo?
                if mongo?
                    @database.connString = "mongodb://#{mongo.hostname}:#{mongo.port}/#{mongo.db}"

            # Check for MongoLab variables.
            mongoLab = env.MONGOLAB_URI
            @database.connString = mongoLab if mongoLab? and mongoLab isnt ""

            # Check for MongoHQ variables.
            mongoHq = env.MONGOHQ_URL
            @database.connString = mongoHq if mongoHq? and mongoHq isnt ""

        # Update logger settings (Logentries and Loggly).
        if not filter or filter.indexOf("logger") >= 0
            logentriesToken = env.LOGENTRIES_TOKEN
            logglyToken = env.LOGGLY_TOKEN
            logglySubdomain = env.LOGGLY_SUBDOMAIN
            @logger.logentries.token = logentriesToken if logentriesToken? and logentriesToken isnt ""
            @logger.loggly.token = logglyToken if logglyToken? and logglyToken isnt ""
            @logger.loggly.subdomain = logglySubdomain if logglySubdomain? and logglySubdomain isnt ""

        # Update mailer settings (Mailgun, Mandrill, SendGrid).
        if not filter or filter.indexOf("mail") >= 0
            currentSmtpHost = @mailer.smtp.host?.toLowerCase()
            currentSmtpHost = "" if not currentSmtpHost?

            # Get and set Mailgun.
            if currentSmtpHost.indexOf("mailgun") >= 0 or smtpHost?.indexOf("mailgun") >= 0
                @mailer.smtp.service = "mailgun"
                smtpUser = env.MAILGUN_SMTP_LOGIN
                smtpPassword = env.MAILGUN_SMTP_PASSWORD

                if smtpUser? and smtpUser isnt "" and smtpPassword? and smtpPassword isnt ""
                    @mailer.smtp.user = smtpUser
                    @mailer.smtp.password = smtpPassword

            # Get and set Mandrill.
            if currentSmtpHost.indexOf("mandrill") >= 0 or smtpHost?.indexOf("mandrill") >= 0
                @mailer.smtp.service = "mandrill"
                smtpUser = env.MANDRILL_USERNAME
                smtpPassword = env.MANDRILL_APIKEY

                if smtpUser? and smtpUser isnt "" and smtpPassword? and smtpPassword isnt ""
                    @mailer.smtp.user = smtpUser
                    @mailer.smtp.password = smtpPassword

            # Get and set SendGrid.
            if currentSmtpHost.indexOf("sendgrid") >= 0 or smtpHost?.indexOf("sendgrid") >= 0
                @mailer.smtp.service = "sendgrid"
                smtpUser = env.SENDGRID_USERNAME
                smtpPassword = env.SENDGRID_PASSWORD

                if smtpUser? and smtpUser isnt "" and smtpPassword? and smtpPassword isnt ""
                    @mailer.smtp.user = smtpUser
                    @mailer.smtp.password = smtpPassword

        # Log to console.
        if @general.debug and @logger.console
            console.log "Settings.updateFromPaaS", "Updated!", filter

# Singleton implementation
# -----------------------------------------------------------------------------
Settings.getInstance = ->
    if process.env is "test"
        obj = new Settings()
        obj.load()
        obj.logger.console = false
        return obj

    if not @instance?
        @instance = new Settings()
        @instance.load()

    return @instance

module.exports = exports = Settings.getInstance()
