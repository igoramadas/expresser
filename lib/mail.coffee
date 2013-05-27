# EXPRESSER MAIL
# --------------------------------------------------------------------------
# Sends and manages emails, supports templates. When parsing templates, the
# tags should be wrapped with normal brackets {}. Example: {contents}
# Parameters on settings.coffee: Settings.Mail

class Mail

    fs = require "fs"
    logger = require "./logger.coffee"
    mailer = require "nodemailer"
    moment = require "moment"
    path = require "path"
    settings = require "./settings.coffee"

    # SMTP objects will be instantiated on `init`.
    smtp = null
    smtp2 = null

    # Templates cache to avoid disk reads.
    templateCache = {}


    # INTERNAL FEATURES
    # -------------------------------------------------------------------------

    # Helper to set the SMTP objects.
    createSmtp = (opt) ->
        options =
            debug: settings.General.debug,
            host: opt.host,
            port: opt.port,
            secureConnection: opt.secure,
            auth:
                user: opt.user,
                pass: opt.password

        # Log SMTP creation.
        logger.info "Expresser", "Mail.createSmtp", options.host, options.port, options.secureConnection

        # Create and return SMTP object.
        return mailer.createTransport "SMTP", options

    # Helper to send emails using the specified transport and options.
    smtpSend = (transport, options, callback) ->
        transport.sendMail options, (err, result) ->
            if err?
                logger.error "Expresser", "Mail.smtpSend", transport.host, "Could not send: #{options.subject} to #{options.to}.", err
            else if settings.General.debug
                logger.info "Mail.smtpSend", transport.host, options.subject, "to #{options.to}", "from #{options.from}."
            callback err, result


    # INIT
    # --------------------------------------------------------------------------

    # Init the SMTP transport objects.
    init: =>
        if settings.Mail.smtp.host? and settings.Mail.smtp.host isnt "" and settings.Mail.smtp.port > 0
            smtp = createSmtp settings.Mail.smtp
        if settings.Mail.smtp2.host? and settings.Mail.smtp2.host isnt "" and settings.Mail.smtp2.port > 0
            smtp2 = createSmtp settings.Mail.smtp2

        # Warn if no SMTP is available for sending emails, but only when debug is enabled.
        if not smtp? and not smtp2? and settings.General.debug
            logger.warn "Expresser", "Mail.init", "No main SMTP host/port specified.", "No emails will be sent out!"


    # OUTBOUND
    # --------------------------------------------------------------------------

    # Sends an email to the specified address. The `obj` will be parsed and transformed
    # to a HTML formatted message. A callback can be specified, having (err, result).
    send: (message, subject, toAddress, fromAddress, callback) ->
        if not smtp? and not smtp2?
            logger.warn "Expresser", "Mail.send", "SMTP transport wasn't initiated. Abort!", subject, "to #{toAddress}"
            return

        if not message? or message is ""
            logger.warn "Expresser", "Mail.send", "Message is not valid. Abort!", subject, "to #{toAddress}"
            return

        # Set from to default address if no `fromAddress` was set and create the options object.
        fromAddress = "#{settings.General.appTitle} <#{settings.Mail.from}>" if not fromAddress?
        options = {}

        # Properly format the "to" address.
        if toAddress.indexOf("<") < 3
            toName = toAddress
        else
            toName = toAddress.substring 0, toAddress.indexOf("<") - 1

        # Replace common keywords.
        html = @parseTemplate message.toString(), {to: toName, appTitle: settings.General.appTitle}

        # Set the message options.
        options.from = fromAddress
        options.to = toAddress
        options.subject = subject
        options.html = html

        # Send using the main SMTP. If failed and a secondary is also set, try using the secondary.
        smtpSend smtp, options, (err, result) ->
            if err?
                if smtp2?
                    smtpSend smtp2, options, (err2, result2) -> callback err2, result2
                else
                    callback err, result
            else
                callback err, result


    # TEMPLATES
    # --------------------------------------------------------------------------

    # Load the specified template from the cache or from the disk if it wasn't loaded yet.
    # Templates are stored inside the `/emailtemplates` folder by default and should
    # have a .html extension. The contents will be inserted on the {contents} tag.
    getTemplate: (name) =>
        cached = templateCache[name]
        if cached? and cached.expires > moment()
            return templateCache[name].template

        # Read base and `name` template and merge them together.
        base = fs.readFileSync path.join(settings.Path.emailTemplatesDir, "base.html")
        template = fs.readFileSync path.join(settings.Path.emailTemplatesDir, "#{name}.html")
        result = base.toString().replace "{contents}", template.toString()

        # Save to cache.
        templateCache[name] = {}
        templateCache[name].template = result
        templateCache[name].expires = moment().add "s", settings.General.ioCacheTimeout

        return result

    # Parse the specified template and replace `keywords` with the correspondent values of
    # the `obj` argument. For example if keywords is `{id: 1, friendlyUrl: "abc"}` then the tags
    # `{id}` and `{friendlyUrl}` will be replaced with the values 1 and abc.
    parseTemplate: (template, keywords) =>
        template = template.toString()

        for key, value of keywords
            template = template.replace new RegExp("\\{#{key}\\}", "gi"), value

        return template


    # HELPER METHODS
    # --------------------------------------------------------------------------

    # Force clear the templates cache.
    clearCache: =>
        count = Object.keys(templateCache).length
        templateCache = {}
        logger.info "Expresser", "Mail.clearCache", "Cleared #{count} templates."


# Singleton implementation
# --------------------------------------------------------------------------
Mail.getInstance = ->
    @instance = new Mail() if not @instance?
    return @instance

module.exports = exports = Mail.getInstance()