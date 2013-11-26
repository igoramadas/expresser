# EXPRESSER MAIL
# --------------------------------------------------------------------------
# Sends and manages emails, supports templates. When parsing templates, the
# tags should be wrapped with normal brackets {}. Example: {contents}
# <!--
# @see Settings.mail
# -->
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
            debug: settings.general.debug,
            host: opt.host,
            port: opt.port,
            secureConnection: opt.secure,
            auth:
                user: opt.user,
                pass: opt.password

        # Log SMTP creation.
        logger.info "Mail.createSmtp", options.host, options.port, options.secureConnection

        # Create and return SMTP object.
        return mailer.createTransport "SMTP", options

    # Helper to send emails using the specified transport and options.
    smtpSend = (transport, options, callback) ->
        transport.sendMail options, (err, result) ->
            if err?
                logger.error "Mail.smtpSend", transport.host, "Could not send: #{options.subject} to #{options.to}.", err
            else
                logger.debug "Mail.smtpSend", transport.host, options.subject, "to #{options.to}", "from #{options.from}."
                callback err, result


    # INIT
    # --------------------------------------------------------------------------

    # Init the SMTP transport objects.
    init: =>
        if settings.mail.smtp.host? and settings.mail.smtp.host isnt "" and settings.mail.smtp.port > 0
            smtp = createSmtp settings.mail.smtp
        if settings.mail.smtp2.host? and settings.mail.smtp2.host isnt "" and settings.mail.smtp2.port > 0
            smtp2 = createSmtp settings.mail.smtp2

        # Warn if no SMTP is available for sending emails, but only when debug is enabled.
        if not smtp? and not smtp2? and settings.general.debug
            logger.warn "Mail.init", "No main SMTP host/port specified.", "No emails will be sent out!"


    # OUTBOUND
    # --------------------------------------------------------------------------

    # Sends an email to the specified address. A callback can be specified, having (err, result).
    #
    # @param [String] options The email message options
    # @option options [String] body The email body in text or HTML.
    # @option options [String] subject The email subject.
    # @option options [String] to The "to" address.
    # @option options [String] from The "from" address, optional, if blank use default from settings.
    # @param [Function] callback Callback (err, result) when message is sent or fails.
    send: (options, callback) ->
        if not smtp? and not smtp2?
            logger.warn "Mail.send", "SMTP transport wasn't initiated. Abort!", options
            return

        # Make sure message body is valid.
        if not options.body? or options.body is false or options.body is ""
            logger.warn "Mail.send", "Option 'body' is not valid. Abort!", options
            return

        # Make sure "to" address is valid.
        if not options.to? or options.to is false or options.to is ""
            logger.warn "Mail.send", "Option 'to' is not valid. Abort!", options
            return

        # Set from to default address if no `to` was set.
        options.to = "#{settings.general.appTitle} <#{settings.mail.from}>" if not options.to?

        # Get the name of recipient based on the `to` option.
        if options.to.indexOf("<") < 3
            toName = options.to
        else
            toName = options.to.substring 0, toAddress.indexOf("<") - 1

        # Replace common keywords and set HTML.
        html = @parseTemplate options.body.toString(), {to: toName, appTitle: settings.general.appTitle}
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
        base = fs.readFileSync path.join(settings.path.emailTemplatesDir, "base.html")
        template = fs.readFileSync path.join(settings.path.emailTemplatesDir, "#{name}.html")
        result = base.toString().replace "{contents}", template.toString()

        # Save to cache.
        templateCache[name] = {}
        templateCache[name].template = result
        templateCache[name].expires = moment().add "s", settings.general.ioCacheTimeout

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
        logger.info "Mail.clearCache", "Cleared #{count} templates."


# Singleton implementation
# --------------------------------------------------------------------------
Mail.getInstance = ->
    @instance = new Mail() if not @instance?
    return @instance

module.exports = exports = Mail.getInstance()