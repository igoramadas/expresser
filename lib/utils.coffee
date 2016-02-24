# EXPRESSER UTILS
# -----------------------------------------------------------------------------
# General network, IO, client and server utilities. As this module can't reference
# any other module but Settings, all its logging will be done to the console only.
class Utils

    crypto = require "crypto"
    fs = require "fs"
    lodash = require "lodash"
    moment = require "moment"
    os = require "os"
    path = require "path"
    settings = require "./settings.coffee"

    # Temporary variable used to calculate CPU usage.
    lastCpuLoad = null

    # SERVER INFO UTILS
    # --------------------------------------------------------------------------

    # Helper to get the correct filename for general files. For example
    # the settings.json file or cron.json for cron jobs. This will look into the current
    # directory, the running directory and the root directory of the app.
    # Returns null if no file is found.
    # @param [String] filename The base filename (with extension) of the config file.
    # @return [String] The full path to the config file if one was found, or null.
    getFilePath: (filename) ->
        originalFilename = "./" + filename.toString()

        # Check if file exists.
        hasFile = fs.existsSync filename
        return filename if hasFile

        # Try current path...
        filename = path.resolve __dirname, originalFilename
        hasFile = fs.existsSync filename
        return filename if hasFile

        # Try parent path...
        filename = path.resolve __dirname, "../", originalFilename
        hasFile = fs.existsSync filename
        return filename if hasFile

        # If file does not exist on local path, try application root path.
        filename = path.resolve path.dirname(require.main.filename), originalFilename
        hasFile = fs.existsSync filename
        return filename if hasFile

        # Nothing found, so return null.
        return null

    # Returns a list of valid server IP addresses. If `firstOnly` is true it will
    # return only the very first IP address found.
    # @param [Boolean] firstOnly Optional, default is false which returns an array with all valid IPs, true returns a String will first valid IP.
    # @return The server IPv4 address, or null.
    getServerIP: (firstOnly) ->
        ifaces = os.networkInterfaces()
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
    # @return [Object] Results with process pid, platform, memory, uptime and IP.
    getServerInfo: =>
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

    # CLIENT INFO UTILS
    # --------------------------------------------------------------------------

    # Get the client or browser IP. Works for http and socket requests, even when behind a proxy.
    # @param [Object] reqOrSocket The request or socket object.
    # @return [String] The client IP address, or null.
    getClientIP: (reqOrSocket) ->
        return null if not reqOrSocket?

        # Try getting the xforwarded header first.
        if reqOrSocket.header?
            xfor = reqOrSocket.header "X-Forwarded-For"
            if xfor? and xfor isnt ""
                return xfor.split(",")[0]

        # Get remote address.
        if reqOrSocket.connection?
            return reqOrSocket.connection.remoteAddress
        else
            return reqOrSocket.remoteAddress

    # Get the client's device. This identifier string is based on the user agent.
    # @param [Object] req The request object.
    # @return [String] The client's device.
    getClientDevice: (req) ->
        return "unknown" if not req?.headers?

        ua = req.headers["user-agent"]

        # Find mobile devices.
        return "mobile-windows-10" if ua.indexOf("Windows Phone 10") > 0
        return "mobile-windows-8" if ua.indexOf("Windows Phone 8") > 0
        return "mobile-windows-7" if ua.indexOf("Windows Phone 7") > 0
        return "mobile-windows" if ua.indexOf("Windows Phone") > 0
        return "mobile-iphone-7" if ua.indexOf("iPhone7") > 0
        return "mobile-iphone-6" if ua.indexOf("iPhone6") > 0
        return "mobile-iphone-5" if ua.indexOf("iPhone5") > 0
        return "mobile-iphone-4" if ua.indexOf("iPhone4") > 0
        return "mobile-iphone" if ua.indexOf("iPhone") > 0
        return "mobile-android-7" if ua.indexOf("Android 7") > 0
        return "mobile-android-6" if ua.indexOf("Android 6") > 0
        return "mobile-android-5" if ua.indexOf("Android 5") > 0
        return "mobile-android-4" if ua.indexOf("Android 4") > 0
        return "mobile-android" if ua.indexOf("Android") > 0

        # Find desktop browsers.
        return "desktop-edge" if ua.indexOf("Edge/") > 0
        return "desktop-opera" if ua.indexOf("Opera/") > 0
        return "desktop-chrome" if ua.indexOf("Chrome/") > 0
        return "desktop-firefox" if ua.indexOf("Firefox/") > 0
        return "desktop-safari" if ua.indexOf("Safari/") > 0
        return "desktop-ie-11" if ua.indexOf("MSIE 11") > 0
        return "desktop-ie-10" if ua.indexOf("MSIE 10") > 0
        return "desktop-ie-9" if ua.indexOf("MSIE 9") > 0
        return "desktop-ie" if ua.indexOf("MSIE") > 0 or if ua.indexOf("Trident") > 0

        # Return default desktop value if no specific devices were found on user agent.
        return "desktop"

    # IO AND DATAUTILS
    # --------------------------------------------------------------------------

    # Copy the `src` file to the `target`, both must be the full file path.
    # @param [String] src The full source file path.
    # @param [String] target The full target file path.
    copyFileSync: (src, target) =>
        srcContents = fs.readFileSync src
        fs.writeFileSync target, srcContents

    # Make sure the "target" directory exists by recursively iterating through its parents
    # and creating the directories. Returns nothing if all good or error.
    mkdirRecursive: (target) =>
        callback = (p, made) ->
            made = null if not made

            p = path.resolve p

            try
                fs.mkdirSync p
            catch ex
                if ex.code is "ENOENT"
                    made = callback path.dirname(p), made
                    callback p, made
                else
                    try
                        stat = fs.statSync p
                    catch ex1
                        throw ex
                    if not stat.isDirectory()
                        throw ex

            return made

        return callback target

    # Removes all the specified characters from a string. For example you can cleanup
    # telephone numbers by using removeFromString(phone, [" ", "-", "(", ")"]).
    # @param [String] value The original value / string.
    # @param {array] charsToRemove List of characters to be removed from the original string.
    # @return [String] Resulting value with the characters removed.
    removeFromString: (value, charsToRemove) =>
        result = value
        result = result.toString() if not lodash.isString result
        result = result.split(c).join("") for c in charsToRemove

        return result

    # Minify the passed JSON value. Removes comments, unecessary white spaces etc.
    # @param [String] source The JSON text to be minified.
    # @param [Boolean] asString If true, return as string instead of JSON object.
    # @return [String] The minified JSON, or an empty string if there's an error.
    minifyJson: (source, asString) ->
        source = JSON.stringify source if typeof source is "object"
        index = 0
        length = source.length
        result = ""
        symbol = undefined
        position = undefined

        # Main iterator.
        while index < length

            symbol = source.charAt index
            switch symbol

                # Ignore whitespace tokens. According to ES 5.1 section 15.12.1.1,
                # whitespace tokens include tabs, carriage returns, line feeds, and
                # space characters.
                when "\t", "\r"
                , "\n"
                , " "
                    index += 1

                # Ignore line and block comments.
                when "/"
                    symbol = source.charAt(index += 1)
                    switch symbol

                        # Line comments.
                        when "/"
                            position = source.indexOf("\n", index)

                            # Check for CR-style line endings.
                            position = source.indexOf("\r", index)  if position < 0
                            index = (if position > -1 then position else length)

                        # Block comments.
                        when "*"
                            position = source.indexOf("*/", index)
                            if position > -1

                                # Advance the scanner's position past the end of the comment.
                                index = position += 2
                                break
                            throw SyntaxError "Unterminated block comment."
                        else
                            throw SyntaxError "Invalid comment."

                # Parse strings separately to ensure that any whitespace characters and
                # JavaScript-style comments within them are preserved.
                when "\""
                    position = index
                    while index < length
                        symbol = source.charAt(index += 1)
                        if symbol is "\\"

                            # Skip past escaped characters.
                            index += 1
                        else break  if symbol is "\""
                    if source.charAt(index) is "\""
                        result += source.slice(position, index += 1)
                        break
                    throw SyntaxError "Unterminated string."

                # Preserve all other characters.
                else
                    result += symbol
                    index += 1

        # Check if should return as string or JSON.
        if asString
            return result
        else
            return JSON.parse result

    # Generates a RFC1422-compliant unique ID using random numbers.
    uuid: =>
        baseStr = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
        generator = (c) ->
            r = Math.random() * 16 | 0
            v = if c is "x" then r else (r & 0x3|0x8)
            v.toString 16

        return baseStr.replace(/[xy]/g, generator)

# Singleton implementation
# --------------------------------------------------------------------------
Utils.getInstance = ->
    return new Utils() if process.env is "test"
    @instance = new Utils() if not @instance?
    return @instance

module.exports = exports = Utils.getInstance()
