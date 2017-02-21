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
    newInstance: ->
        obj = new Settings()
        obj.load()
        return obj

    crypto = require "crypto"
    events = require "./events.coffee"
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

        events.emit "Settings.on.load"

    # Helper to load values from the specified settings file.
    # @param {String} filename The filename or path to the settings file.
    # @param {Boolean} extend If true it won't update settings that are already existing.
    # @return {Object} Returns the JSON representation of the loaded file.
    loadFromJson: (filename, extend) =>
        extend = false if not extend?
        filename = utils.getFilePath filename
        settingsJson = null

        # Has json? Load it. Try using UTF8 first, if failed, use ASCII.
        if filename?
            encUtf8 = {encoding: "utf8"}
            encAscii = {encoding: "ascii"}

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
                    else if not extend or not target[prop]?
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

    # Helper to encrypt or decrypt settings files. The default encryption key
    # defined on the `Settings.coffee` file is "ExpresserSettings", which
    # you should change to your desired value. You can also set the key
    # via the EXPRESSER_SETTINGS_CRYPTOKEY environment variable.
    # The default cipher algorithm is AES 256.
    # @param {Boolean} encrypt Pass true to encrypt, false to decrypt.
    # @param {String} filename The file to be encrypted or decrypted.
    # @param {Object} options Options to be passed to the cipher.
    # @option options {String} cipher The cipher to be used, default is aes256.
    # @option options {String} password The encryption key.
    cryptoHelper: (encrypt, filename, options) =>
        env = process.env

        options = {} if not options?
        options = lodash.defaults options, {cipher: "aes256", key: env["EXPRESSER_SETTINGS_CRYPTOKEY"]}
        options.key = "ExpresserSettings" if not options.key? or options.key is ""
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
                            c = crypto.createCipher options.cipher, options.key
                            newValue += c.update currentValue.toString(), @general.encoding, "hex"
                            newValue += c.final "hex"

                        else

                            # Split the data as "datatype:encryptedValue".
                            arrValue = currentValue.split ":"
                            newValue = ""

                            # Create cipher and decrypt.
                            c = crypto.createDecipher options.cipher, options.key
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
        fs.writeFileSync filename, newSettingsJson, {encoding: @general.encoding}
        return true

    # Helper to encrypt the specified settings file. Please see `cryptoHelper` above.
    # @param {String} filename The file to be encrypted.
    # @param {Object} options Options to be passed to the cipher.
    # @return {Boolean} Returns true if encryption OK, false if something went wrong.
    encrypt: (filename, options) =>
        @cryptoHelper true, filename, options

    # Helper to decrypt the specified settings file. Please see `cryptoHelper` above.
    # @param {String} filename The file to be decrypted.
    # @param {Object} options Options to be passed to the cipher.
    # @return {Boolean} Returns true if decryption OK, false if something went wrong.
    decrypt: (filename, options) =>
        @cryptoHelper false, filename, options

    # FILE WATCHER
    # --------------------------------------------------------------------------

    # Enable or disable the settings files watcher to auto reload settings when file changes.
    # The `callback` is optional in case you want to notify another module about settings updates.
    # @param {Boolean} enable If enabled is true activate the fs watcher, otherwise deactivate.
    # @param {Method} callback A function (event, filename) triggered when a settings file changes.
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

# Singleton implementation
# -----------------------------------------------------------------------------
Settings.getInstance = ->
    if not @instance?
        @instance = new Settings()
        @instance.load()

    return @instance

module.exports = exports = Settings.getInstance()
