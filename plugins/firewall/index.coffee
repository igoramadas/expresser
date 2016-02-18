# EXPRESSER FIREWALL
# -----------------------------------------------------------------------------
# Firewall to protect the server against well known HTTP and socket attacks.
# It attaches itself automatically to the internal Express app when enabled.
# <!--
# @see settings.firewall
# -->
class Firewall

    util = require "util"

    logger = null
    moment = null
    settings = null
    utils = null

    # Holds a collection of blacklisted IPs.
    blacklist: null

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

    # Bind the firewall to the server. This must be called AFTER the web app has started.
    # @param [Object] options Firewall init options.
    # @option options [Object] server The Express server object to bind.
    init: (options) =>
        logger = @expresser.logger
        moment = @expresser.libs.moment
        settings = @expresser.settings
        utils = @expresser.utils

        logger.debug "Firewall.init", options

        options = {server: options} if not options.server?

        # Server is mandatory!
        if not options.server?
            logger.error "Firewall.init", "App server is invalid. Abort!"
            return null

        # Bind HTTP protection.
        if settings.firewall.httpPatterns isnt ""
            @expresser.app.prependMiddlewares.push @checkHttpRequest
            logger.info "Firewall.init", "Protecting HTTP requests."

        # Bind sockets protection.
        if settings.firewall.socketPatterns isnt ""
            logger.info "Firewall.init", "Protecting Socket requests."

        @blacklist = {}

    # HTTP PROTECTION
    # -------------------------------------------------------------------------

    # Check HTTP requests against common web attacks.
    checkHttpRequest: (req, res, next) =>
        ip = utils.getClientIP req

        # If IP is blaclisted, end the request immediatelly.
        if @checkBlacklist ip
            @sendAccessDenied res, "Blacklisted"

        # Helper method to check HTTP patterns.
        check = (p) => @checkHttpPattern p, req, res

        # Set valid and checl all enabled patterns.
        valid = true
        enabledPatterns = settings.firewall.httpPatterns.split ","
        for pattern in enabledPatterns
            valid = false if check(pattern)

        # Only proceed if request is valid.
        next() if valid

    # Test the request against the enabled protection patterns.
    checkHttpPattern: (module, req, res) =>
        p = patterns[module].length - 1

        while p >= 0
            if patterns[module][p].test req.url
                @handleHttpAttack "#{module}", p, req, res
                return true
            --p

        return false

    # Handle attacks.
    handleHttpAttack: (module, pattern, req, res) =>
        ip = utils.getClientIP req

        @logAttack module, pattern, req.url, ip
        @sendAccessDenied res

    # SOCKETS PROTECTION
    # -------------------------------------------------------------------------

    # Check Socket requests against common web attacks.
    checkSocketRequest: (socket, message, next) =>
        ip = utils.getClientIP req

        # If IP is blaclisted, end the request immediatelly.
        if @checkBlacklist ip
            @sendAccessDenied socket, "Blacklisted"

        # Helper method to check socket patterns.
        check = (p) => @checkSocketPattern p, socket, util.inspect(message)

        # Set valid and checl all enabled patterns.
        valid = true
        enabledPatterns = settings.firewall.socketPatterns.split ","
        for pattern in enabledPatterns
            valid = false if check(pattern)

        # Only proceed if request is valid.
        next() if valid

    # Test the request against the enabled protection patterns.
    checkSocketPattern: (module, socket, message) =>
        p = patterns[module].length - 1

        while p >= 0
            if patterns[module][p].test message
                @handleSocketAttack "#{module}", p, socket, message
                return
            --p

    # Handle attacks.
    handleSocketAttack: (module, pattern, socket, message) =>
        ip = utils.getClientIP socket
        @logAttack module, pattern, message, ip
        @sendAccessDenied socket

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
        if bl.count >= settings.firewall.blacklistMaxRetries
            bl.expires = moment().add settings.firewall.blacklistLongExpires, "s"

        return true

    # Add the specified IP to the blacklist.
    addToBlacklist: (ip) =>
        bl = @blacklist[ip]
        bl = {} if not bl?

        # Set blacklist object.
        bl.expires = moment().add settings.firewall.blacklistExpires, "s"
        bl.count = 1

        @blacklist[ip] = bl

    # HELPER METHODS
    # -------------------------------------------------------------------------

    # Send an access denied and end the request in case it wasn't authorized.
    sendAccessDenied: (obj, message) =>
        message = "Access denied" if not message?

        # Set status and message.
        obj.status(403) if obj.status? and not obj.headerSent
        obj.send(message) if obj.send?

        # Disconnect or end?
        if obj.disconnect?
            return obj.disconnect()
        else
            return obj.end()

    # Log attacks.
    logAttack: (module, pattern, resource, ip) =>
        logger.warn "ATTACK DETECTED!", module, pattern, resource, "From #{ip}"

# Singleton implementation
# --------------------------------------------------------------------------
Firewall.getInstance = ->
    @instance = new Firewall() if not @instance?
    return @instance

module.exports = exports = Firewall.getInstance()