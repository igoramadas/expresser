# EXPRESSER
# -----------------------------------------------------------------------------
fs = require "fs"
path = require "path"

isTest = process.env.NODE_ENV is "test"
isProduction = process.env.NODE_ENV is "production"

###
# A platform for Node.js web apps, built on top of Express. This is the main wrapper.
###
class Expresser
    newInstance: -> return new Expresser()

    # Set application root path.
    rootPath: path.dirname require.main.filename

    # Preload the main modules. App must be the last module to be set.
    errors: require "./errors.coffee"
    settings: require "./settings.coffee"
    utils: require "./utils.coffee"
    events: require "./events.coffee"
    logger: require "./logger.coffee"
    app: require "./app.coffee"

    # Expose 3rd party modules.
    libs:
        async: require "async"
        express: require "express"
        lodash: require "lodash"
        moment: require "moment"

    # Holds all loaded plugins.
    plugins: {}

    # Helper to load default modules. Basically everything inside the lib folder.
    initDefaultModules: =>
        modules = fs.readdirSync __dirname

        for id, m of this
            if id isnt "app" and modules.indexOf(id) >= 0
                @[id].init?()

    # Helper to load plugins. This will look first inside a /plugins
    # folder for local development setups, or directly under /node_modules
    # for plugins installed via NPM (most production scenarios).
    loadPlugins: =>
        initializers = []
        pluginsPath = path.resolve __dirname, "../plugins"

        if fs.existsSync(pluginsPath) and not isProduction
            pluginsFolder = true
            plugins = fs.readdirSync pluginsPath
        else
            pluginsFolder = false
            plugins = fs.readdirSync "#{@rootPath}/node_modules"

        # Iterate and set up plugins.
        if not isTest
            for p in plugins
                pluginId = p.substring(p.lastIndexOf("/") + 1)

                if pluginsFolder or pluginId.substring(0, 10) is "expresser-"
                    pluginName = pluginId.replace "expresser-", ""

                    # Check if plugin was already attached.
                    if not @plugins[pluginName]?
                        if pluginsFolder
                            pluginSettingsPath = "#{__dirname}/../plugins/#{p}/settings.default.json"
                        else
                            pluginSettingsPath = "#{@rootPath}/node_modules/#{pluginId}/settings.default.json"

                        # Check if there are default settings to be loaded for the plugin.
                        if fs.existsSync pluginSettingsPath
                            @settings.loadFromJson pluginSettingsPath, true

                        # Get options accordingly to plugin name.
                        pluginArr = pluginName.split "-"
                        optionsRef = @settings
                        i = 0

                        while i < pluginArr.length
                            optionsRef = optionsRef?[pluginArr[i]]
                            i++

                        # Only load if plugin is enabled.
                        if optionsRef?.enabled
                            if pluginsFolder or not fs.existsSync("#{__dirname}/../../#{pluginId}")
                                @plugins[pluginName] = require "../plugins/#{pluginName}"
                            else
                                @plugins[pluginName] = require pluginId

                            # Attach itself to the plugin.
                            @plugins[pluginName].expresser = this
                            initializers.push {priority: @plugins[pluginName].priority, plugin: @plugins[pluginName]}

            sortedInit = @libs.lodash.sortBy initializers, ["priority"]

            # Init all loaded plugins on the correct order.
            for i in sortedInit
                i.plugin.init?()

    ###
    # Helper to init all modules. Load settings first, then Logger, then general
    # modules, and finally the App.
    ###
    init: =>
        process.on "exit", (code) =>
            appTitle = @settings.app?.title or "app"
            console.warn "Quitting #{appTitle}...", code

        @initDefaultModules()
        @loadPlugins()

        # Accept invalid certificates?
        if not @settings.app.ssl.rejectUnauthorized
            process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"

        # App must be the last thing to be started!
        @app.expresser = this
        @app.init() if not isTest

# Singleton implementation
# --------------------------------------------------------------------------
Expresser.getInstance = ->
    @instance = new Expresser() if not @instance?
    return @instance

module.exports = Expresser.getInstance()
