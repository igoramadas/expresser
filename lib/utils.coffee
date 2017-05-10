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

    # DEPRECATED METHODS
    # --------------------------------------------------------------------------

    getFilePath: (filename) =>
        console.warn "utils.getFilePath", "DEPRECATED!", "Please use utils.io.getFilePath."
        return @io.getFilePath filename

    getServerIP: (firstOnly) =>
        console.warn "utils.getIP", "DEPRECATED!", "Please use utils.system.getIP."
        return @system.getIP firstOnly

    getServerInfo: =>
        console.warn "utils.getInfo", "DEPRECATED!", "Please use utils.system.getInfo."
        return @system.getInfo()

    getCpuLoad: =>
        console.warn "utils.getCpuLoad", "DEPRECATED!", "Please use utils.system.getCpuLoad."
        return @system.getCpuLoad()

    ipInRange: (ip, range) =>
        console.warn "Utils.ipInRange", "DEPRECATED!", "Please use utils.network.ipInRange."
        return @network.ipInRange ip, range

    getClientIP: (reqOrSocket) =>
        console.warn "utils.getClientIP", "DEPRECATED!", "Please use utils.browser.getClientIP."
        return @browser.getClientIP reqOrSocket

    getClientDevice: (req) =>
        console.warn "utils.getDeviceString", "DEPRECATED!", "Please use utils.browser.getDeviceString."
        return @browser.getDeviceString req

    copyFileSync: (src, target) =>
        console.warn "Utils.copyFileSync", "DEPRECATED!", "Please use utils.io.copyFileSync."
        return @io.copyFileSync src, target

    mkdirRecursive: (target) =>
        console.warn "utils.mkdirRecursive", "DEPRECATED!", "Please use utils.io.mkdirRecursive."
        return @io.mkdirRecursive target

    removeFromString: (value, charsToRemove) =>
        console.warn "Utils.removeFromString", "DEPRECATED!", "Please use utils.data.removeFromString."
        return @data.removeFromString value, charsToRemove

    maskString: (value, maskChar, leaveLast) =>
        console.warn "Utils.maskString", "DEPRECATED!", "Please use utils.data.maskString."
        return @data.maskString value, maskChar, leaveLast

    minifyJson: (source, asString) =>
        console.warn "utils.minifyJson", "DEPRECATED!", "Please use utils.data.minifyJson."
        return @data.minifyJson source, asString

    uuid: =>
        console.warn "Utils.uuid", "DEPRECATED!", "Please use utils.data.uuid."
        return @data.uuid()

# Singleton implementation
# --------------------------------------------------------------------------
Utils.getInstance = ->
    @instance = new Utils() if not @instance?
    return @instance

module.exports = exports = Utils.getInstance()
