# EXPRESSER
# -----------------------------------------------------------------------------
# A platform and template for Node.js web apps, built on top of Express.
# If you need help, check the project page at http://expresser.codeplex.com.

class Expresser

    # Settings.
    settings: require "./lib/settings.coffee"

    # Expresser modules.
    app: require "./lib/app.coffee"
    database: require "./lib/database.coffee"
    firewall: require "./lib/firewall.coffee"
    imaging: require "./lib/imaging.coffee"
    logger: require "./lib/logger.coffee"
    mail: require "./lib/mail.coffee"
    sockets: require "./lib/sockets.coffee"
    twitter: require "./lib/twitter.coffee"
    utils: require "./lib/utils.coffee"

    # Helper to init all modules. Logger first, then general modules, and finally the App.
    init: =>
        @logger.init()

        @database.init()
        @mail.init()
        @twitter.init()

        # App must be the last thing to be started!
        # The Firewall and Sockets modules are initiated inside the App module.
        @app.init()


# Singleton implementation
# --------------------------------------------------------------------------
Expresser.getInstance = ->
    @instance = new Expresser() if not @instance?
    return @instance

module.exports = exports = Expresser.getInstance()