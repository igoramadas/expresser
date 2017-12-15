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
    browser: require "./utils/browser.coffee"

    ##
    # Data parsing and processing utilities.
    # @property
    data: require "./utils/data.coffee"

    ##
    # IO utilities.
    # @property
    io: require "./utils/io.coffee"

    ##
    # Network utilities.
    # @property
    network: require "./utils/network.coffee"

    ##
    # System and server utilities.
    # @property
    system: require "./utils/system.coffee"

# Singleton implementation
# --------------------------------------------------------------------------
Utils.getInstance = ->
    @instance = new Utils() if not @instance?
    return @instance

module.exports = Utils.getInstance()