# EXPRESSER UTILS
# -----------------------------------------------------------------------------
# General network, IO, client and server utilities.
class Utils
    newInstance: -> return new Utils()

    browser: require "./utils/browser.coffee"
    data: require "./utils/data.coffee"
    io: require "./utils/io.coffee"
    network: require "./utils/network.coffee"
    system: require "./utils/system.coffee"

# Singleton implementation
# --------------------------------------------------------------------------
Utils.getInstance = ->
    @instance = new Utils() if not @instance?
    return @instance

module.exports = exports = Utils.getInstance()
