# EXPRESSER UTILS: NETWORK
# -----------------------------------------------------------------------------
# Network utilities.
class NetworkUtils
    newInstance: -> return new NetworkUtils()

    ipaddr = require "ipaddr.js"

    # Check if a specific IP is in the provided range.
    # @param {String} ip The IP to be checked (IPv4 or IPv6).
    # @param {Object} range A string or array of strings representing the valid ranges.
    # @return {Boolean} True if valid, false otherwise.
    ipInRange: (ip, range) =>
        if lodash.isString range
            ipParsed = ipaddr.parse ip
            ipVer = ipParsed.kind()

            # Range is a subnet? Then parse the IP address and check each block against the range.
            if range.indexOf("/") >= 0
                try
                    rangeArr = range.split "/"
                    rangeParsed = ipaddr.parse rangeArr[0]

                    return ipParsed.match rangeParsed, rangeArr[1]
                catch err
                    return false

            # Range is a single IP address.
            else
                return ip is range

        # Array of IP ranges, check each one of them.
        else if lodash.isObject range
            for r of range
                return true if @ipInRange ip, range[r]

        return false

# Singleton implementation
# --------------------------------------------------------------------------
NetworkUtils.getInstance = ->
    @instance = new NetworkUtils() if not @instance?
    return @instance

module.exports = exports = NetworkUtils.getInstance()
