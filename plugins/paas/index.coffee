# EXPRESSER METRICS
# --------------------------------------------------------------------------
# Auto configure the Expresser app and its modules to work on known PaaS
# providers, mainly by checking cloud environmental variables.
# <!--
# @see settings.paas
# -->
class PaaS

    events = null
    lodash = null
    logger = null
    settings = null

    env = null

    # INIT
    # --------------------------------------------------------------------------

    # Init the PaaS plugin.
    init: (options) =>
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        settings = @expresser.settings

        env = process.env

        @setEvents()

    # Bind events.
    setEvents: =>
        events.on "App.before.init", => @appSettings()
        events.on "Database.before.init", => @databaseSettings()
        events.on "Logger.before.init", => @loggerSettings()
        events.on "Mailer.before.init", => @mailerSettings()

    # SETTINGS
    # --------------------------------------------------------------------------

    # Update app settings.
    appSettings: =>
        ip = env.OPENSHIFT_NODEJS_IP or env.IP
        port = env.OPENSHIFT_NODEJS_PORT or env.VCAP_APP_PORT or env.PORT
        settings.app.ip = ip if ip? and ip isnt ""
        settings.app.port = port if port? and port isnt ""

        if settings.logger.console
            console.log "PaaS.appSettings", "App settings were auto updated."

    # Update database settings.
    databaseSettings: =>
        vcap = env.VCAP_SERVICES
        vcap = JSON.parse vcap if vcap? and lodash.isString vcap

        settings.database.mongodb = {} if not settings.database.mongodb?

        # Check for AppFog MongoDB variables.
        if vcap? and vcap isnt ""
            mongo = vcap["mongodb-1.8"]
            mongo = mongo[0]["credentials"] if mongo?
            if mongo?
                settings.database.mongodb.connString = "mongodb://#{mongo.hostname}:#{mongo.port}/#{mongo.db}"

        # Check for MongoLab variables.
        mongoLab = env.MONGOLAB_URI
        settings.database.mongodb.connString = mongoLab if mongoLab? and mongoLab isnt ""

        # Check for MongoHQ variables.
        mongoHq = env.MONGOHQ_URL
        settings.database.mongodb.connString = mongoHq if mongoHq? and mongoHq isnt ""

        if settings.logger.console
            console.log "PaaS.databaseSettings", "Database settings were auto updated."

    # Update logger settings.
    loggerSettings: =>
        logentriesToken = env.LOGENTRIES_TOKEN
        logglyToken = env.LOGGLY_TOKEN
        logglySubdomain = env.LOGGLY_SUBDOMAIN

        settings.logger.logentries = {} if not settings.logger.logentries?
        settings.logger.loggly = {} if not settings.logger.loggly?

        settings.logger.logentries.token = logentriesToken if logentriesToken? and logentriesToken isnt ""
        settings.logger.loggly.token = logglyToken if logglyToken? and logglyToken isnt ""
        settings.logger.loggly.subdomain = logglySubdomain if logglySubdomain? and logglySubdomain isnt ""

        if settings.logger.console
            console.log "PaaS.loggerSettings", "Logger settings were auto updated."

    # Update mailer settings.
    mailerSettings: =>
        currentSmtpHost = settings.mailer?.smtp?.host?.toLowerCase()
        currentSmtpHost = "" if not currentSmtpHost?

        # Get and set Mailgun.
        if currentSmtpHost.indexOf("mailgun") >= 0 or smtpHost?.indexOf("mailgun") >= 0
            settings.mailer.smtp.service = "mailgun"
            smtpUser = env.MAILGUN_SMTP_LOGIN
            smtpPassword = env.MAILGUN_SMTP_PASSWORD

            if smtpUser? and smtpUser isnt ""
                settings.mailer.smtp.user = smtpUser

            if smtpPassword? and smtpPassword isnt ""
                settings.mailer.smtp.password = smtpPassword

        # Get and set Mandrill.
        if currentSmtpHost.indexOf("mandrill") >= 0 or smtpHost?.indexOf("mandrill") >= 0
            settings.mailer.smtp.service = "mandrill"
            smtpUser = env.MANDRILL_USERNAME
            smtpPassword = env.MANDRILL_APIKEY

            if smtpUser? and smtpUser isnt ""
                settings.mailer.smtp.user = smtpUser

            if smtpPassword? and smtpPassword isnt ""
                settings.mailer.smtp.password = smtpPassword

        # Get and set SendGrid.
        if currentSmtpHost.indexOf("sendgrid") >= 0 or smtpHost?.indexOf("sendgrid") >= 0
            settings.mailer.smtp.service = "sendgrid"
            smtpUser = env.SENDGRID_USERNAME
            smtpPassword = env.SENDGRID_PASSWORD

            if smtpUser? and smtpUser isnt ""
                settings.mailer.smtp.user = smtpUser

            if smtpPassword? and smtpPassword isnt ""
                settings.mailer.smtp.password = smtpPassword

        if settings.logger.console
            console.log "PaaS.mailerSettings", "Mailer settings were auto updated."

# Singleton implementation
# --------------------------------------------------------------------------
PaaS.getInstance = ->
    @instance = new PaaS() if not @instance?
    return @instance

module.exports = exports = PaaS.getInstance()
