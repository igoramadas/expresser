# EXPRESSER
# -----------------------------------------------------------------------------
# A platform and template for Node.js web apps, built on top of Express.
# If you need help, check the project page at http://expresser.codeplex.com.

class Expresser

    # Settings.
    settings: require "./lib/settings.coffee"

    # Expresser modules.
    app: require "./lib/app.coffee"
    cron: require "./lib/cron.coffee"
    database: require "./lib/database.coffee"
    downloader: require "./lib/downloader.coffee"
    events: require "./lib/events.coffee"
    firewall: require "./lib/firewall.coffee"
    imaging: require "./lib/imaging.coffee"
    logger: require "./lib/logger.coffee"
    mailer: require "./lib/mailer.coffee"
    sockets: require "./lib/sockets.coffee"
    utils: require "./lib/utils.coffee"

    # Helper to init all modules. Load settings first, then Logger, then general
    # modules, and finally the App. The `options` can have properties to be
    # passed to the `init` of each module.
    # @param [Object] options Options to be passed to each init module.
    # @option options [Object] app Pass options to the App init.
    # @option options [Object] database Pass options to the Database init.
    # @option options [Object] logger Pass options to the Logger init.
    # @option options [Object] mailer Pass options to the Mailer init.
    init: (options) =>
        @logger.init options?.logger
        @database.init options?.database
        @mailer.init options?.mailer

        # App must be the last thing to be started!
        # The Firewall and Sockets modules are initiated inside the App module.
        @app.init options?.app

        # Check for deprecated / moved features.
        if process.versions.node.indexOf(".6.") > 0
            loggerMsg = "Attention! Support for Node.js 0.6 will be dropped soon, please consider upgrading to 0.10."
            @logger.debug "Expresser.init", loggerMsg
        if @settings.mail?
            loggerMsg = "Attention! The 'mail' module was renamed to 'mailer', please update your code if necessary!"
            @logger.debug "Expresser.init", loggerMsg
            @mail = @mailer


# Singleton implementation
# --------------------------------------------------------------------------
Expresser.getInstance = ->
    @instance = new Expresser() if not @instance?
    return @instance

module.exports = exports = Expresser.getInstance()