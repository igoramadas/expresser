# EXPRESSER UTILS
# -----------------------------------------------------------------------------
# General utilities.
class Utils
    newInstance: -> return new Utils()

    # @property {Object} Browser utils.
    browser: require "./utils/browser.coffee"

    # @property {Object} Data utils.
    data: require "./utils/data.coffee"

    # @property {Object} IO utils.
    io: require "./utils/io.coffee"

    # @property {Object} Network utils.
    network: require "./utils/network.coffee"

    # @property {Object} System utils.
    system: require "./utils/system.coffee"

# Singleton implementation
# --------------------------------------------------------------------------
Utils.getInstance = ->
    @instance = new Utils() if not @instance?
    return @instance

module.exports = Utils.getInstance()
