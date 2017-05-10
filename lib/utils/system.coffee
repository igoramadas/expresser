# EXPRESSER UTILS: SYSTEM
# -----------------------------------------------------------------------------
# System and server utilities.
class SystemUtils
    newInstance: -> return new SystemUtils()

    moment = require "moment"
    os = require "os"

    # Temporary variable used to calculate CPU usage.
    lastCpuLoad = null

    # Returns a list of valid server IP addresses. If `firstOnly` is true it will
    # return only the very first IP address found.
    # @param {Boolean} firstOnly Optional, default is false which returns an array with all valid IPs, true returns a String will first valid IP.
    # @return {String} The server IPv4 address, or null.
    getIP: (firstOnly) ->
        try
            ifaces = os.networkInterfaces()
        catch ex
            # On Windows Bash this and other corner case systems this can be unavailable.
            return {error: ex}

        result = []

        # Parse network interfaces and try getting the server IPv4 address.
        for i of ifaces
            ifaces[i].forEach (details) ->
                if details.family is "IPv4" and not details.internal
                    result.push details.address

        # Return only first IP or all of them?
        if firstOnly
            return result[0]
        else
            return result

    # Return an object with general information about the server.
    # @return {Object} Results with process pid, platform, memory, uptime and IP.
    getInfo: =>
        result = {}

        # Save parsed OS info to the result object.
        result.uptime = moment.duration(process.uptime(), "s").humanize()
        result.hostname = os.hostname()
        result.title = path.basename process.title
        result.platform = os.platform() + " " + os.arch() + " " + os.release()
        result.memoryTotal = (os.totalmem() / 1024 / 1024).toFixed(0) + " MB"
        result.memoryUsage = 100 - (os.freemem() / os.totalmem() * 100).toFixed(0)
        result.ips = @getServerIP()
        result.process = {pid: process.pid, memoryUsage: (process.memoryUsage().rss / 1024 / 1024).toFixed(0) + " MB"}
        result.cpuCores = os.cpus().length

        # Calculate average CPU load.
        lastCpuLoad = @getCpuLoad() if not lastCpuLoad?
        currentCpuLoad = @getCpuLoad()
        idleDifference = currentCpuLoad.idle - lastCpuLoad.idle
        totalDifference = currentCpuLoad.total - lastCpuLoad.total

        result.loadAvg = 100 - ~~(100 * idleDifference / totalDifference)

        return result

    # Get current CPU load (used mainly by getServerInfo).
    # @return {Object} CPU load with idle and total ticks.
    getCpuLoad: ->
        totalIdle = 0
        totalTick = 0
        cpus = os.cpus()
        i = 0
        len = cpus.length

        while i < len
            cpu = cpus[i]
            totalTick += value for t, value of cpu.times
            totalIdle += cpu.times.idle
            i++

        return {idle: totalIdle / cpus.length, total: totalTick / cpus.length}

# Singleton implementation
# --------------------------------------------------------------------------
SystemUtils.getInstance = ->
    @instance = new SystemUtils() if not @instance?
    return @instance

module.exports = exports = SystemUtils.getInstance()
