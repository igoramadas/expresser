# EXPRESSER UTILS: BROWSER
# -----------------------------------------------------------------------------
# Browser and client utilities.
class BrowserUtils
    newInstance: -> return new BrowserUtils()

    # Get the client or browser IP. Works for http and socket requests, even when behind a proxy.
    # @param {Object} reqOrSocket The request or socket object.
    # @return {String} The client IP address, or null.
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
    # @param {Object} req The request object.
    # @return {String} The client's device.
    getDeviceString: (req) ->
        return "unknown" if not req?.headers?

        ua = req.headers["user-agent"]

        return "unknown" if not ua? or ua is ""

        # Find mobile devices.
        return "mobile-windows-10" if ua.indexOf("Windows 10 Mobile") > 0
        return "mobile-windows-8" if ua.indexOf("Windows Phone 8") > 0
        return "mobile-windows-7" if ua.indexOf("Windows Phone 7") > 0
        return "mobile-windows" if ua.indexOf("Windows Mobile") > 0
        return "mobile-iphone-8" if ua.indexOf("iPhone8") > 0
        return "mobile-iphone-7" if ua.indexOf("iPhone7") > 0
        return "mobile-iphone-6" if ua.indexOf("iPhone6") > 0
        return "mobile-iphone-5" if ua.indexOf("iPhone5") > 0
        return "mobile-iphone-4" if ua.indexOf("iPhone4") > 0
        return "mobile-iphone" if ua.indexOf("iPhone") > 0
        return "mobile-android-9" if ua.indexOf("Android 9") > 0
        return "mobile-android-8" if ua.indexOf("Android 8") > 0
        return "mobile-android-7" if ua.indexOf("Android 7") > 0
        return "mobile-android-6" if ua.indexOf("Android 6") > 0
        return "mobile-android-5" if ua.indexOf("Android 5") > 0
        return "mobile-android-4" if ua.indexOf("Android 4") > 0
        return "mobile-android" if ua.indexOf("Android") > 0

        # Find desktop browsers.
        return "desktop-vivaldi" if ua.indexOf("Vivaldi/") > 0
        return "desktop-edge" if ua.indexOf("Edge/") > 0
        return "desktop-opera" if ua.indexOf("Opera/") > 0
        return "desktop-chrome" if ua.indexOf("Chrome/") > 0
        return "desktop-firefox" if ua.indexOf("Firefox/") > 0
        return "desktop-safari" if ua.indexOf("Safari/") > 0
        return "desktop-ie" if ua.indexOf("MSIE") > 0 or ua.indexOf("Trident") > 0

        # Return default desktop value if no specific devices were found on user agent.
        return "unknown"

# Singleton implementation
# --------------------------------------------------------------------------
BrowserUtils.getInstance = ->
    @instance = new BrowserUtils() if not @instance?
    return @instance

module.exports = BrowserUtils.getInstance()
