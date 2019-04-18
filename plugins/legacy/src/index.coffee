# EXPRESSER LEGACY
# -----------------------------------------------------------------------------
fs = require "fs"
path = require "path"
setmeup = require "setmeup"
isTest = process.env.NODE_ENV is "test"

###
# Adapter to make Expresser v3 apps compatible with v4.
###
class ExpresserLegacy
    init: (expresser) =>
        expresser = require("expresser") if not expresser?

        # Set correct root path.
        if isTest
            expresser.rootPath = path.dirname __dirname
        else
            expresser.rootPath = path.dirname require.main.filename

        # App is Expresser itself.
        expresser.app = expresser

        # Links to new replacement modules.
        expresser.logger = require("anyhow")
        expresser.settings = setmeup.settings
        expresser.utils = require("jaul")

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

        process.on "exit", (code) =>
            appTitle = expresser.settings.app?.title or "app"
            console.warn "Quitting #{appTitle}...", code

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
                        setmeup.load pluginSettingsPath, true

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

        # Accept invalid certificates?
        if not expresser.settings.app.ssl.rejectUnauthorized
            process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"

        # App must be the last thing to be started!
        expresser.expresser = expresser
        expresser.init()

# Singleton implementation
# --------------------------------------------------------------------------
ExpresserLegacy.getInstance = ->
    @instance = new ExpresserLegacy() if not @instance?
    return @instance

module.exports = ExpresserLegacy.getInstance()
