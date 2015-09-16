# EXPRESSER
# -----------------------------------------------------------------------------
# A platform for Node.js web apps, built on top of Express.
# If you need help check the project page at http://github.com/igoramadas/expresser.
class Expresser

    fs = require "fs"
    path = require "path"

    # Set application root path.
    rootPath: path.dirname require.main.filename

    # Preload the main modules. App must be the last module to be set.
    settings: require "./lib/settings.coffee"
    utils: require "./lib/utils.coffee"
    events: require "./lib/events.coffee"
    logger: require "./lib/logger.coffee"
    database: require "./lib/database.coffee"
    app: require "./lib/app.coffee"

    # Expose 3rd party modules.
    libs:
        async: require "async"
        lodash: require "lodash"
        moment: require "moment"

    # Helper to load default modules. Basically everything inside the lib folder.
    initDefaultModules = (self, options) ->
        for id, m of self
            if id isnt "app" and m?.init? and self.settings[id]?.enabled
                self[id].init? options?[id]

    # Helper to load plugins. This will look first inside a /plugins
    # folder for local development setups, or directly under /node_modules
    # for plugins installed via NPM (most production scenarios).
    loadPlugins = (self, options) ->
        if fs.existsSync "#{__dirname}/plugins"
            pluginsFolder = true
            plugins = fs.readdirSync "#{__dirname}/plugins"
        else
            pluginsFolder = false
            plugins = fs.readdirSync "#{self.rootPath}/node_modules"

        plugins.sort()

        # Iterate plugins and get it's ID by removing the "expresser-" prefix.
        for p in plugins
            pluginId = p.substring(p.lastIndexOf("/") + 1)

            if pluginId.substring(0, 10) is "expresser-"
                pluginName = pluginId.replace "expresser-", ""

                # Check if plugin was already attached.
                if not self[pluginName]?
                    if pluginsFolder
                        self[pluginName] = require "./plugins/#{pluginId}"
                        pluginSettingsPath = path.dirname(p) + "settings.default.json"
                    else
                        self[pluginName] = require pluginId
                        pluginSettingsPath = "#{self.rootPath}/node_modules/#{pluginId}/settings.default.json"

                    # Attach itself to the plugin.
                    self[pluginName].expresser = self

                # Check if there are default settings to be loaded for the plugin.
                if fs.existsSync pluginSettingsPath
                    self.settings.loadFromJson pluginSettingsPath

                # Init plugin only if enabled is not set to false on its settings.
                if self.settings[pluginName]?.enabled
                    self[pluginName].init? options?[pluginName]

    # Helper to init all modules. Load settings first, then Logger, then general
    # modules, and finally the App. The `options` can have properties to be
    # passed to the `init` of each module.
    # @param [Object] options Options to be passed to each init module.
    init: (options) =>
        options = {} if not options?

        initDefaultModules this, options
        loadPlugins this, options

        # App must be the last thing to be started!
        # The Firewall and Sockets modules are initiated inside the App
        # depending on their settings.
        @app.expresser = this
        @app.init options?.app

# Singleton implementation
# --------------------------------------------------------------------------
Expresser.getInstance = ->
    @instance = new Expresser() if not @instance?
    return @instance

module.exports = exports = Expresser.getInstance()
