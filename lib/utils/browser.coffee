# EXPRESSER UTILS: BROWSER
# -----------------------------------------------------------------------------
util = require "util"

###
# Browser and client utilities.
###
class BrowserUtils
    newInstance: -> return new BrowserUtils()

    ###
    # Get the client IP. Works for http and socket requests, even when behind a proxy.
    # @param {express-Request} reqOrSocket The request or socket object.
    # @return {String} The client IP address, or null if not identified.
    ###
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

    ###
    # Get the client's device details. This is a very basic helper to identify device and browser.
    # If you're looking into a more advanced detection, supporting more browsers and user agents,
    # please check the `useragent` NPM module.
    # @param {express-Request} req The request object, mandatory.
    # @return {Object} The client's device details.
    ###
    getDeviceDetails: (req) ->
        result = {
            device: "Unkknown"
            browser: "Unknown"
        }

        return result if not req?.headers?
        ua = req.headers["user-agent"]?.toLowerCase().replace(/\s/g, "").replace(/_/g, "")
        return result if not ua? or ua is ""

        # Detect browser.
        if ua.indexOf("edge/") > 0
            result.browser = "Edge"
        else if ua.indexOf("msie") > 0
            result.browser = "Internet Explorer"
        else if ua.indexOf("firefox")
            result.browser = "Firefox"
        else if ua.indexOf("vivaldi/") > 0
            result.browser = "Vivaldi"
        else if ua.indexOf("chrome/") > 0 or ua.indexOf("chromium/") > 0
            result.browser = "Chrome"

        # Detect Android devices.
        android = ua.indexOf("android")
        if android > 0
            result.device = "Android"
            version = ua.substring android + 7, 1
            result.device += " #{version}" if not isNaN version
            return result

        # Detect iPhones.
        iphone = ua.indexOf("iphone")
        if iphone > 0
            result.device = "iPhone"
            version = ua.substring iphone + 6, 1
            result.device += " #{version}" if not isNaN version
            return result

        # Detect iPads.
        ipad = ua.indexOf("iphone")
        if ipad > 0
            result.device = "iPad"
            return result

        # Detect Mac OS X.
        mac = ua.indexOf("macosx")
        if mac > 0
            result.device = "macOS"
            version = ua.substring mac + 8, 2
            result.device += " 10.#{version}" if not isNaN version
            return result

        # Detect Windows Mobile.
        winmobile = ua.indexOf("windowsmobile")
        winmobile = ua.indexOf("windowsphone") if winmobile < 0
        if winmobile > 0
            result.device = "Windows Mobile"
            return result

        # Detect Windows Desktop.
        win = ua.indexOf("windows")
        if win > 0
            result.device = "Windows"
            return result

        # Detect Windows Mobile.
        linux = ua.indexOf("linux")
        if linux > 0
            result.device = "Linux"
            return result

        return result

    # DEPRECATED! Please use `getDeviceDetails` instead.
    getDeviceString: (req) =>
        deprecated = => return @getDeviceDetails req
        return util.deprecate deprecated, "BrowserUtils.getDeviceString: use getDeviceDetails instead."

# Singleton implementation
# --------------------------------------------------------------------------
BrowserUtils.getInstance = ->
    @instance = new BrowserUtils() if not @instance?
    return @instance

module.exports = BrowserUtils.getInstance()
