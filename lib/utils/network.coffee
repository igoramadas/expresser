# EXPRESSER UTILS: NETWORK
# -----------------------------------------------------------------------------
errors = require "../errors.coffee"
ipaddr = require "ipaddr.js"
lodash = require "lodash"
os = require "os"

###
# Network utilities.
###
class NetworkUtils
    newInstance: -> return new NetworkUtils()

    ###
    # Returns a list of valid server IPv4 and/or IPv6 addresses.
    # @param {String} family IP family to be retrieved, can be "IPv4" or "IPv6".
    # @return {Array} Array with the system's IP addresses, or empty.
    ###
    getIP: (family) ->
        result = []

        try
            ifaces = os.networkInterfaces()
        catch ex
            errors.throw "noNetworkInterfaces", ex
            return result

        family = family.toLowerCase() if family?

        # Parse network interfaces and try getting the valid IP addresses.
        for i of ifaces
            ifaces[i].forEach (details) ->
                if not details.internal and (not family? or details.family.toLowerCase() is family)
                    result.push details.address

        return result
    ###
    # Returns the first valid IPv4 address found on the system, or null if no valid IPs were found.
    # @return {String} First valid IPv4 address, or null.
    ###
    getSingleIPv4: =>
        ips = @getIP "ipv4"
        return ips[0] if ips?.length > 0
        return null

    ###
    # Returns the first valid IPv6 address found on the system, or null if no valid IPs were found.
    # @return {String} First valid IPv6 address, or null.
    ###
    getSingleIPv6: =>
        ips = @getIP "ipv6"
        return ips[0] if ips?.length > 0
        return null

    ###
    # Check if a specific IP is in the provided range.
    # @param {String} ip The IP to be checked (IPv4 or IPv6).
    # @param {Array} range A string or array of strings representing the valid ranges.
    # @return {Boolean} True if IP is in range, false otherwise.
    ###
    ipInRange: (ip, range) ->
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

module.exports = NetworkUtils.getInstance()
