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
    twitter: require "./lib/twitter.coffee"
    utils: require "./lib/utils.coffee"

    # Helper to init all modules. Load settings first, then Logger, then general
    # modules, and finally the App. The `options` can have properties to be
    # passed to the `init` of each module.
    # @param [Object] initOptions Options to be passed to each init module.
    # @option initOptions [Object] app Pass options to the App init.
    # @option initOptions [Object] app Pass options to the App init.
    init: (initOptions) =>
        @utils.loadDefaultSettingsFromJson()

        # Init the Logger.
        @logger.init initOptions?.logger

        # Init general modules.
        @database.init initOptions?.database
        @mailer.init initOptions?.mailer
        @twitter.init initOptions?.twitter

        # App must be the last thing to be started!
        # The Firewall and Sockets modules are initiated inside the App module.
        @app.init initOptions?.app

        # Updated mail to mailer.
        mailerMsg = "Attention! The 'mail' module was renamed to 'mailer', please update your code if necessary!"
        @logger.debug "Expresser.init", mailerMsg
        @mail = @mailer


# Singleton implementation
# --------------------------------------------------------------------------
Expresser.getInstance = ->
    @instance = new Expresser() if not @instance?
    return @instance

module.exports = exports = Expresser.getInstance()