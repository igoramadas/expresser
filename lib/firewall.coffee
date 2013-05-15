# EXPRESSER LOGGER
# -----------------------------------------------------------------------------
# Handles server logging using Logentries or Loggly. Please make sure to
# set the correct parameters on the (log settings)[settings.html].

class Firewall

    async = require "async"
    lodash = require "lodash"
    logger = require "./logger.coffee"
    moment = require "moment"
    settings = require "./settings.coffee"
    util = require "util"

    # Holds a collection of blacklisted IPs.
    blacklist: {}


    # PROTECTION PATTERNS
    # -------------------------------------------------------------------------
    patterns = {}
    patterns.lfi = [/\.\.\//] # root path match
    patterns.sql = [/((\%3D)|(=))[^\n]*((\%27)|(\')|(\-\-)|(\%3B)|(;))/i, # SQL meta chars
                    /\w*((\%27)|(\'))((\%6F)|o|(\%4F))((\%72)|r|(\%52))/i, # simple SQL injection
                    /((\%27)|(\'))union/i, # union SQL injection
                    /exec(\s|\+)+(s|x)p\w+/i, # MSSQL specific injection
                    /UNION(?:\s+ALL)?\s+SELECT/i] # union select SQL injection
    patterns.xss = [/((\%3C)|<)((\%2F)|\/)*[a-z0-9\%]+((\%3E)|>)/i, # simple XSS
                    /((\%3C)|<)((\%69)|i|(\%49))((\%6D)|m|(\%4D))((\%67)|g|(\%47))[^\n]+((\%3E)|>)/i, # img src XSS
                    /((\%3C)|<)[^\n]+((\%3E)|>)/i] # all other XSS


    # INIT
    # -------------------------------------------------------------------------

    # Init the Logger. Verify which service is set, and add the necessary transports.
    # IP address and timestamp will be appended to logs depending on the [settings](settings.html).
    init: =>
        logger.info()


    # HTTP PROTECTION
    # -------------------------------------------------------------------------

    # Check HTTP requests against common web attacks.
    checkHttpRequest: (req, res, next) =>
        ip = @getClientIP req

        # If IP is blaclisted, end the request immediatelly.
        @sendAccessDenied res if @checkBlacklist ip

        # Helper method to check patterns.
        check = (p, call) =>
            @checkHttpPattern p, req, res
            call()

        enabledPatterns = settings.Firewall.httpPatterns.split ","
        async.each enabledPatterns, check, null

        next() if next?

    # Test the request against the enabled protection patterns.
    checkHttpPattern: (module, req, res) =>
        p = @patterns[module].length - 1

        while p >= 0
            if patterns[module][p].test req.url
                @handleHttpAttack "#{module}", p, req, res
                return
            --p

    # Handle attacks.
    handleHttpAttack: (module, pattern, req, res) =>
        ip = @getClientIP req
        @logAttack module, pattern, req.url, ip

        res.end()


    # SOCKETS PROTECTION
    # -------------------------------------------------------------------------

    # Check Socket requests against common web attacks.
    checkSocketRequest: (socket, message, next) =>
        ip = @getClientIP req

        # If IP is blaclisted, end the request immediatelly.
        @sendAccessDenied socket if @checkBlacklist ip

        # Helper method to check patterns.
        check = (p, call) =>
            @checkSocketPattern p, socket, util.inspect(message)
            call()

        enabledPatterns = settings.Firewall.socketPatterns.split ","
        async.each enabledPatterns, check, null

        next() if next?

    # Test the request against the enabled protection patterns.
    checkSocketPattern: (module, socket, message) =>
        p = @patterns[module].length - 1

        while p >= 0
            if patterns[module][p].test message
                @handleSocketAttack "#{module}", p, socket, message
                return
            --p

    # Handle attacks.
    handleSocketAttack: (module, pattern, socket, message) =>
        ip = @getClientIP socket
        @logAttack module, pattern, message, ip


    # BLACKLIST METHODS
    # -------------------------------------------------------------------------

    # Reset the blacklist object.
    clearBlacklist: =>
        @blacklist = {}

    # Check if the specified IP is blacklisted.
    checkBlacklist: (ip) =>
        bl = @blacklist[ip]

        if not bl?
            return false

        # Check if record has expired.
        if bl.expires < moment()
            delete @blacklist[ip]
            return false

        # Increase the blacklist count, and increase the expiry date in case
        # it has reached the max retries.
        bl.count = bl.count + 1
        if bl.count >= settings.Firewall.blacklistMaxRetries
            bl.expires = moment().add "s", settings.Firewall.blacklistLongExpires

        return true

    # Add the specified IP to the blacklist.
    addToBlacklist: (ip) =>
        bl = @blacklist[ip]
        bl = {} if not bl?

        # Set blacklist object.
        bl.expires = moment().add "s", settings.Firewall.blacklistExpires
        bl.count = 1

        @blacklist[ip] = bl


    # HELPER METHODS
    # -------------------------------------------------------------------------

    # Send an access denied and end the request in case it wasn't authorized.
    sendAccessDenied: (obj) =>
        obj.writeHead 403 if obj.writeHead?

        # Disconnect or end?
        if obj.disconnect?
            obj.disconnect()
        else
            obj.end()

    # Log attacks.
    logAttack: (module, pattern, resource, ip) =>
        logger.warn "Expresser", "ATTACK DETECTED!", module, pattern, resource, "From #{ip}"

    # Get the client / browser IP, even when behind proxies. Works for http and socket requests.
    getClientIP: (reqOrSocket) =>
        if not reqOrSocket?
            return null

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


# Singleton implementation
# --------------------------------------------------------------------------
Firewall.getInstance = ->
    @instance = new Firewall() if not @instance?
    return @instance

module.exports = exports = Firewall.getInstance()