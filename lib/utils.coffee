# EXPRESSER UTILS
# -----------------------------------------------------------------------------
# General network, IO and other utilities.

class Utils

    os = require "os"
    settings = require "./settings.coffee"


    # SETTINGS UTILS
    # --------------------------------------------------------------------------

    # Update settings based on Cloud Environmental variables.
    updateSettingsFromPaaS: =>
        env = process.env

        # Temporary variables with current values.
        currentSmtpHost = settings.Mail.smtp.host?.toLowerCase()

        # Check for web (IP and port) variables.
        ip = env.OPENSHIFT_NODEJS_IP or env.OPENSHIFT_INTERNAL_IP or env.IP
        port = env.OPENSHIFT_NODEJS_PORT or env.OPENSHIFT_INTERNAL_PORT or env.VCAP_APP_PORT or env.PORT
        settings.App.ip = ip if ip? and ip isnt ""
        settings.App.port = port if port? and port isnt ""

        # Check for MongoDB on AppFog variables.
        vcap = env.VCAP_SERVICES
        vcap = JSON.parse vcap if vcap?
        if vcap? and vcap isnt ""
            mongo = vcap["mongodb-1.8"]
            mongo = mongo[0]["credentials"] if mongo?
            if mongo?
                settings.Database.connString = "mongodb://#{mongo.hostname}:#{mongo.port}/#{mongo.db}"

        # Check for MongoLab variables.
        mongoLab = env.MONGOLAB_URI
        settings.Database.connString = mongoLab if mongoLab? and mongoLab isnt ""

        # Check for MongoHQ variables.
        mongoHq = env.MONGOHQ_URL
        settings.Database.connString = mongoHq if mongoHq? and mongoHq isnt ""

        # Check for Logentries and Loggly variables.
        logentriesToken = env.LOGENTRIES_TOKEN
        logglyToken = env.LOGGLY_TOKEN
        logglySubdomain = env.LOGGLY_SUBDOMAIN
        settings.Logger.Logentries.token = logentriesToken if logentriesToken? and logentriesToken isnt ""
        settings.Logger.Loggly.token = logglyToken if logglyToken? and logglyToken isnt ""
        settings.Logger.Loggly.subdomain = logglySubdomain if logglySubdomain? and logglySubdomain isnt ""

        # Check for SendGrid (email) variables.
        smtpUser = env.SENDGRID_USERNAME
        smtpPassword = env.SENDGRID_PASSWORD
        if currentSmtpHost?.indexOf("sendgrid") > 0
            settings.Mail.smtp.user = smtpUser if smtpUser? and smtpUser isnt ""
            settings.Mail.smtp.password = smtpPassword if smtpPassword? and smtpPassword isnt ""

        # Check for Mandrill (email) variables.
        smtpUser = env.MANDRILL_USERNAME
        smtpPassword = env.MANDRILL_APIKEY
        if currentSmtpHost?.indexOf("mandrill") > 0
            settings.Mail.smtp.user = smtpUser if smtpUser? and smtpUser isnt ""
            settings.Mail.smtp.password = smtpPassword if smtpPassword? and smtpPassword isnt ""

        # Check for Mailgun (email) variables.
        smtpHost = env.MAILGUN_SMTP_SERVER
        smtpPort = env.MAILGUN_SMTP_PORT
        smtpUser = env.MAILGUN_SMTP_LOGIN
        smtpPassword = env.MAILGUN_SMTP_PASSWORD
        settings.Mail.smtp.host = smtpHost if smtpHost? and smtpHost isnt ""
        settings.Mail.smtp.port = smtpPort if smtpPort? and smtpPort isnt ""
        settings.Mail.smtp.user = smtpUser if smtpUser? and smtpUser isnt ""
        settings.Mail.smtp.password = smtpPassword if smtpPassword? and smtpPassword isnt ""


    # SERVER INFO UTILS
    # --------------------------------------------------------------------------

    # Return the first valid server IPv4 address.
    getServerIP: =>
        ifaces = os.networkInterfaces()
        result = ""

        # Parse network interfaces and try getting the server IPv4 address.
        for i of ifaces
            ifaces[i].forEach (details) ->
                if details.family is "IPv4" and not details.internal
                    result = details.address

        return result

    # Return an object with general information about the server.
    getServerInfo: =>
        result = {}

        # Parse server info.
        pid = process.pid + " " + process.title
        platform = process.platform + " " + process.arch + ", v" + process.version
        memUsage = process.memoryUsage()
        memUsage = Math.round(memUsage.headUsed / 1000) + " / " + Math.round(memUsage.heapTotal / 1000) + " MB"
        uptime = moment.duration(process.uptime, "s").humanize()

        # Save parsed info to the result object.
        result.pid = pid
        result.platform = platform
        result.memoryUsage = memUsage
        result.uptime = uptime
        result.ip = @getServerIP()

        return result


    # CLIENT INFO UTILS
    # --------------------------------------------------------------------------

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
Utils.getInstance = ->
    @instance = new Utils() if not @instance?
    return @instance

module.exports = exports = Utils.getInstance()