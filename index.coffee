# EXPRESSER
# -----------------------------------------------------------------------------
# A platform for Node.js web apps, built on top of Express.
# If you need help check the project page at http://expresser.codeplex.com.

class Expresser

    # Settings.
    settings: require "./lib/settings.coffee"

    # App, events and logger are mandatory.
    @app = require "./lib/app.coffee"
    @events = require "./lib/events.coffee"
    @logger = require "./lib/logger.coffee"

    # Enable only modules which have "enabled" set to true.
    @cron = require "./lib/cron.coffee" if settings.cron.enabled
    @database = require "./lib/database.coffee" if settings.database.enabled
    @downloader = require "./lib/downloader.coffee" if settings.downloader.enabled
    @firewall = require "./lib/firewall.coffee" if settings.firewall.enabled
    @imaging = require "./lib/imaging.coffee" if settings.imaging.enabled
    @mailer = require "./lib/mailer.coffee" if settings.mailer.enabled
    @sockets = require "./lib/sockets.coffee" if settings.sockets.enabled
    @utils = require "./lib/utils.coffee" if settings.utils.enabled

    # Expose 3rd party modules.
    libs:
        async: require "async"
        lodash: require "lodash"
        moment: require "moment"

    # Helper to init all modules. Load settings first, then Logger, then general
    # modules, and finally the App. The `options` can have properties to be
    # passed to the `init` of each module.
    # @param [Object] options Options to be passed to each init module.
    # @option options [Object] app Pass options to the App init.
    # @option options [Object] cron Pass options to the Mailer init.
    # @option options [Object] database Pass options to the Database init.
    # @option options [Object] logger Pass options to the Logger init.
    # @option options [Object] mailer Pass options to the Mailer init.
    init: (options) =>
        @logger.init options?.logger

        # Init optional modules.
        @database.init options?.database if @database?
        @mailer.init options?.mailer if @mailer?

        # App must be the last thing to be started!
        # The Firewall and Sockets modules are initiated inside the App
        # depending on their settings.
        @app.init options?.app

# Singleton implementation
# --------------------------------------------------------------------------
Expresser.getInstance = ->
    @instance = new Expresser() if not @instance?
    return @instance

module.exports = exports = Expresser.getInstance()
