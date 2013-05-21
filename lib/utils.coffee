# EXPRESSER UTILS
# -----------------------------------------------------------------------------
# General network, IO and other utilities.

class Utils

    settings = require "./settings.coffee"

    # Update settings based on Cloud Environmental variables.
    updateSettingsFromPaaS: =>
        env = process.env

        # Temporary variables with current values.
        currentSmtpHost = settings.Email.smtp.host?.toLowerCase()

        # Check for web (IP and port) variables.
        ip = env.OPENSHIFT_INTERNAL_IP or env.OPENSHIFT_NODEJS_IP or env.IP
        port = env.OPENSHIFT_INTERNAL_PORT or env.OPENSHIFT_NODEJS_PORT or env.VCAP_APP_PORT or env.PORT
        settings.Web.ip = ip if ip? and ip isnt ""
        settings.Web.port = port if port? and port isnt ""

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
        settings.Log.Logentries.token = logentriesToken if logentriesToken? and logentriesToken isnt ""
        settings.Log.Loggly.token = logglyToken if logglyToken? and logglyToken isnt ""
        settings.Log.Loggly.subdomain = logglySubdomain if logglySubdomain? and logglySubdomain isnt ""

        # Check for SendGrid (email) variables.
        smtpUser = env.SENDGRID_USERNAME
        smtpPassword = env.SENDGRID_PASSWORD
        if currentSmtpHost?.indexOf("sendgrid") > 0
            settings.Email.smtp.user = smtpUser if smtpUser? and smtpUser isnt ""
            settings.Email.smtp.password = smtpPassword if smtpPassword? and smtpPassword isnt ""

        # Check for Mandrill (email) variables.
        smtpUser = env.MANDRILL_USERNAME
        smtpPassword = env.MANDRILL_APIKEY
        if currentSmtpHost?.indexOf("mandrill") > 0
            settings.Email.smtp.user = smtpUser if smtpUser? and smtpUser isnt ""
            settings.Email.smtp.password = smtpPassword if smtpPassword? and smtpPassword isnt ""

        # Check for Mailgun (email) variables.
        smtpHost = env.MAILGUN_SMTP_SERVER
        smtpPort = env.MAILGUN_SMTP_PORT
        smtpUser = env.MAILGUN_SMTP_LOGIN
        smtpPassword = env.MAILGUN_SMTP_PASSWORD
        settings.Email.smtp.host = smtpHost if smtpHost? and smtpHost isnt ""
        settings.Email.smtp.port = smtpPort if smtpPort? and smtpPort isnt ""
        settings.Email.smtp.user = smtpUser if smtpUser? and smtpUser isnt ""
        settings.Email.smtp.password = smtpPassword if smtpPassword? and smtpPassword isnt ""

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