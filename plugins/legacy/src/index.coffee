# EXPRESSER LEGACY
# -----------------------------------------------------------------------------
EventEmitter = require("eventemitter3")
fs = require "fs"
lodash = require "lodash"
path = require "path"
setmeup = require "setmeup"
isTest = process.env.NODE_ENV is "test"

###
# Adapter to make Expresser v3 apps compatible with v4.
###
class ExpresserLegacy
    init: (expresser) =>
        expresser = require("expresser") if not expresser?
        expresser.expresser = expresser

        # Set correct root path.
        if isTest
            expresser.rootPath = path.dirname __dirname
        else
            expresser.rootPath = path.dirname require.main.filename

        # Append events.
        expresser.events = new EventEmitter()

        # Load settings.
        setmeup.load()
        setmeup.load "#{expresser.rootPath}/settings.default.json"
        expresser.setmeup = setmeup
        expresser.settings = setmeup.settings

        # Links to new replacement modules.
        expresser.logger = require "anyhow"
        expresser.utils = require "jaul"

        # Errors helper.
        expresser.errors = require "./errors.coffee"

        # Expose 3rd party modules.
        expresser.libs = {
            async: require "async"
            express: require "express"
            lodash: require "lodash"
            moment: require "moment"
        }

        # Holds all loaded plugins.
        expresser.plugins = {}

        initializers = []
        plugins = fs.readdirSync "#{expresser.rootPath}/node_modules"

        # Iterate and set up plugins.
        for p in plugins
            pluginId = p.substring(p.lastIndexOf("/") + 1)

            if pluginId.substring(0, 10) is "expresser-"
                pluginName = pluginId.replace "expresser-", ""

                # Check if plugin was already attached.
                if not expresser.plugins[pluginName]?
                    pluginSettingsPath = "#{expresser.rootPath}/node_modules/#{pluginId}/settings.default.json"

                    # Check if there are default settings to be loaded for the plugin.
                    if fs.existsSync pluginSettingsPath
                        setmeup.load pluginSettingsPath

                    # Get options accordingly to plugin name.
                    pluginArr = pluginName.split "-"
                    optionsRef = expresser.settings
                    i = 0

                    while i < pluginArr.length
                        optionsRef = optionsRef?[pluginArr[i]]
                        i++

                    # Only load if plugin is enabled.
                    if optionsRef?.enabled
                        expresser.plugins[pluginName] = require pluginId

                        # Attach itself to the plugin.
                        expresser.plugins[pluginName].expresser = expresser
                        initializers.push {priority: expresser.plugins[pluginName].priority, plugin: expresser.plugins[pluginName]}

            sortedInit = expresser.libs.lodash.sortBy initializers, ["priority"]

            # Init all loaded plugins on the correct order.
            for i in sortedInit
                i.plugin.init?()

        # App must be the last thing to be started!
        expresser.app.expresser = expresser

        # Use Connect Assets.
        connectAssetsOptions = lodash.cloneDeep setmeup.settings.app.connectAssets
        ConnectAssets = (require "connect-assets") connectAssetsOptions

        # Init the Expresser app!
        expresser.app.init {append: [ConnectAssets]}

# Singleton implementation
# --------------------------------------------------------------------------
ExpresserLegacy.getInstance = ->
    @instance = new ExpresserLegacy() if not @instance?
    return @instance

module.exports = ExpresserLegacy.getInstance()
