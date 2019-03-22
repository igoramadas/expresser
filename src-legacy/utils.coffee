# EXPRESSER UTILS
# -----------------------------------------------------------------------------

###
# General utilities.
###
class Utils
    newInstance: -> return new Utils()

    ##
    # Browser utilities.
    # @property
    # @type BrowserUtils
    browser: require "./utils/browser.coffee"

    ##
    # Data parsing and processing utilities.
    # @property
    # @type DataUtils
    data: require "./utils/data.coffee"

    ##
    # IO utilities.
    # @property
    # @type IOUtils
    io: require "./utils/io.coffee"

    ##
    # Network utilities.
    # @property
    # @type NetworkUtils
    network: require "./utils/network.coffee"

    ##
    # System and server utilities.
    # @property
    # @type SystemUtils
    system: require "./utils/system.coffee"

# Singleton implementation
# --------------------------------------------------------------------------
Utils.getInstance = ->
    @instance = new Utils() if not @instance?
    return @instance

module.exports = Utils.getInstance()
