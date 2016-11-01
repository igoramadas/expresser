# EXPRESSER SOCKETS
# --------------------------------------------------------------------------
# Auto configure the Expresser app and its modules to work on known PaaS 
# providers, mainly by checking cloud environmental variables.
# <!--
# @see settings.paas
# -->
class PaaS

    events = null
    logger = null
    settings = null

    # INIT
    # --------------------------------------------------------------------------

    # Init the PaaS plugin.
    init: (options) =>
        events = @expresser.events
        logger = @expresser.logger
        settings = @expresser.settings

    # SETTINGS
    # --------------------------------------------------------------------------

    # Update settings based on Cloud Environmental variables. If a `filter` is specified,
    # update only settings that match it, otherwise update everything.
    # @param {String} filter Filter settings to be updated, for example "mailer" or "database".
    updateSettings: (filter) =>
        env = process.env
        filter = false if not filter? or filter is ""

        # Update app IP and port (OpenShift, AppFog).
        if not filter or filter.indexOf("app") >= 0
            ip = env.OPENSHIFT_NODEJS_IP or env.IP
            port = env.OPENSHIFT_NODEJS_PORT or env.VCAP_APP_PORT or env.PORT
            @app.ip = ip if ip? and ip isnt ""
            @app.port = port if port? and port isnt ""

        # Update database settings (AppFog, MongoLab, MongoHQ).
        if not filter or filter.indexOf("database") >= 0
            vcap = env.VCAP_SERVICES
            vcap = JSON.parse vcap if vcap?

            @database.mongodb = {} if not @database.mongodb?

            # Check for AppFog MongoDB variables.
            if vcap? and vcap isnt ""
                mongo = vcap["mongodb-1.8"]
                mongo = mongo[0]["credentials"] if mongo?
                if mongo?
                    @database.mongodb.connString = "mongodb://#{mongo.hostname}:#{mongo.port}/#{mongo.db}"

            # Check for MongoLab variables.
            mongoLab = env.MONGOLAB_URI
            @database.mongodb.connString = mongoLab if mongoLab? and mongoLab isnt ""

            # Check for MongoHQ variables.
            mongoHq = env.MONGOHQ_URL
            @database.mongodb.connString = mongoHq if mongoHq? and mongoHq isnt ""

        # Update logger settings (Logentries and Loggly).
        if not filter or filter.indexOf("logger") >= 0
            logentriesToken = env.LOGENTRIES_TOKEN
            logglyToken = env.LOGGLY_TOKEN
            logglySubdomain = env.LOGGLY_SUBDOMAIN

            @logger.logentries = {} if not @logger.logentries?
            @logger.loggly = {} if not @logger.loggly?

            @logger.logentries.token = logentriesToken if logentriesToken? and logentriesToken isnt ""
            @logger.loggly.token = logglyToken if logglyToken? and logglyToken isnt ""
            @logger.loggly.subdomain = logglySubdomain if logglySubdomain? and logglySubdomain isnt ""

        # Update mailer settings (Mailgun, Mandrill, SendGrid).
        if not filter or filter.indexOf("mail") >= 0
            @mailer = {} if not @mailer?

            currentSmtpHost = @mailer.smtp?.host?.toLowerCase()
            currentSmtpHost = "" if not currentSmtpHost?

            # Get and set Mailgun.
            if currentSmtpHost.indexOf("mailgun") >= 0 or smtpHost?.indexOf("mailgun") >= 0
                @mailer.smtp.service = "mailgun"
                smtpUser = env.MAILGUN_SMTP_LOGIN
                smtpPassword = env.MAILGUN_SMTP_PASSWORD

                if smtpUser? and smtpUser isnt "" and smtpPassword? and smtpPassword isnt ""
                    @mailer.smtp.user = smtpUser
                    @mailer.smtp.password = smtpPassword

            # Get and set Mandrill.
            if currentSmtpHost.indexOf("mandrill") >= 0 or smtpHost?.indexOf("mandrill") >= 0
                @mailer.smtp.service = "mandrill"
                smtpUser = env.MANDRILL_USERNAME
                smtpPassword = env.MANDRILL_APIKEY

                if smtpUser? and smtpUser isnt "" and smtpPassword? and smtpPassword isnt ""
                    @mailer.smtp.user = smtpUser
                    @mailer.smtp.password = smtpPassword

            # Get and set SendGrid.
            if currentSmtpHost.indexOf("sendgrid") >= 0 or smtpHost?.indexOf("sendgrid") >= 0
                @mailer.smtp.service = "sendgrid"
                smtpUser = env.SENDGRID_USERNAME
                smtpPassword = env.SENDGRID_PASSWORD

                if smtpUser? and smtpUser isnt "" and smtpPassword? and smtpPassword isnt ""
                    @mailer.smtp.user = smtpUser
                    @mailer.smtp.password = smtpPassword

        # Log to console.
        if @general.debug and @logger.console
            console.log "Settings.updateFromPaaS", "Updated!", filter
    

# Singleton implementation
# --------------------------------------------------------------------------
PaaS.getInstance = ->
    @instance = new PaaS() if not @instance?
    return @instance

module.exports = exports = PaaS.getInstance()