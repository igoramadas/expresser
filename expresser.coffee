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
    logger: require "./lib/logger.coffee"
    mail: require "./lib/mail.coffee"
    sockets: require "/lib/sockets.coffee"
    twitter: require "./lib/twitter.coffee"

    # Helper to init all modules.
    init: =>
        @logger.init()
        @database.init()
        @mail.init()
        @twitter.init()
        @app.init()
        @sockets.init()


# Singleton implementation
# --------------------------------------------------------------------------
Expresser.getInstance = ->
    @instance = new Expresser() if not @instance?
    return @instance

module.exports = exports = Expresser.getInstance()