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

    ###
    # Return an object with general and health information about the system.
    # @param {Object} options Options to define the output.
    # @option options {Boolean} labels If false, labels won't be added to the output (%, MB, etc). Default is true.
    # @return {Object} Object with system metrics attached.
    ###
    getInfo: (options) =>
        options = {labels: true} if not options?
        result = {}

        # Save parsed OS info to the result object.
        result.uptime = moment.duration(process.uptime(), "s").humanize()
        result.hostname = os.hostname()
        result.title = path.basename process.title
        result.platform = os.platform() + " " + os.arch() + " " + os.release()
        result.memoryTotal = (os.totalmem() / 1024 / 1024).toFixed 0
        result.memoryUsage = 100 - (os.freemem() / os.totalmem() * 100).toFixed 0
        result.cpuCores = os.cpus().length

        # Get process memory stats.
        processMemory = process.memoryUsage()

        result.process = {
            pid: process.pid
            memoryUsed: (processMemory.rss / 1024 / 1024).toFixed 0
            memoryHeapTotal: (processMemory.heapTotal / 1024 / 1024).toFixed 0
            memoryHeapUsed: (processMemory.heapUsed / 1024 / 1024).toFixed 0
        }

        # Calculate average CPU load.
        lastCpuLoad = @getCpuLoad() if not lastCpuLoad?
        currentCpuLoad = @getCpuLoad()
        idleDifference = currentCpuLoad.idle - lastCpuLoad.idle
        totalDifference = currentCpuLoad.total - lastCpuLoad.total
        result.loadAvg = 100 - ~~(100 * idleDifference / totalDifference)

        # Add labels to relevant metrics on the output?
        if options.labels
            result.loadAvg += "%"
            result.memoryTotal += " MB"
            result.memoryUsage += "%"
            result.process.memoryUsed += " MB"
            result.process.memoryHeapTotal += " MB"
            result.process.memoryHeapUsed += " MB"

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
