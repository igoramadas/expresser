# EXPRESSER UTILS: SYSTEM
# -----------------------------------------------------------------------------
moment = require "moment"
os = require "os"
path = require "path"
util = require "util"

# Temporary variable used to calculate CPU usage.
lastCpuLoad = null

###
# System and server utilities.
###
class SystemUtils
    newInstance: -> return new SystemUtils()

    # DEPRECATED! The getIP has moved to the NetworkUtils as GetIPv4.
    getIP: (firstOnly) ->
        deprecated = -> return require("./network.coffee").getIP "ipv4"
        return util.deprecate deprecated, "SystemUtils.getIP: use NetworkUtils.getIP/.getSingleIPv4 instead."

    ###
    # Return an object with general and health information about the system.
    # @return {Object} System uptime, hostname, title, platform, memoryTotal, memoryUsage, process, cpuCores and loadAvg.
    ###
    getInfo: =>
        result = {}

        # Save parsed OS info to the result object.
        result.uptime = moment.duration(process.uptime(), "s").humanize()
        result.hostname = os.hostname()
        result.title = path.basename process.title
        result.platform = os.platform() + " " + os.arch() + " " + os.release()
        result.memoryTotal = (os.totalmem() / 1024 / 1024).toFixed(0) + " MB"
        result.memoryUsage = 100 - (os.freemem() / os.totalmem() * 100).toFixed(0)
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

module.exports = SystemUtils.getInstance()
