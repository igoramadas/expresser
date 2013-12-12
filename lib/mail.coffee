# EXPRESSER MAIL
# --------------------------------------------------------------------------
# Sends and manages emails, supports templates. When parsing templates, the
# tags should be wrapped with normal brackets {}. Example: {contents}
# The base message template (which is loaded with every single sent message)
# must be saved as base.html, under the /emailtemplates folder (or whatever
# folder you have set on the settings).
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

    # Helper to return a SMTP object.
    createSmtp = (opts) ->
        options =
            debug: settings.general.debug,
            host: opts.host,
            port: opts.port,
            secureConnection: opts.secure,
            auth:
                user: opts.user,
                pass: opts.password

        # Log and create SMTP object.
        logger.info "Mail.createSmtp", options.host, options.port, options.secureConnection
        result = mailer.createTransport "SMTP", options

        # Sign using DKIM?
        result.useDKIM settings.mail.dkim if settings.mail.dkim.enabled

        # Return SMTP object.
        return result

    # Helper to send emails using the specified transport and options.
    smtpSend = (transport, options, callback) ->
        transport.sendMail options, (err, result) ->
            if err?
                logger.error "Mail.smtpSend", transport.host, "Could not send: #{options.subject} to #{options.to}.", err
            else
                logger.debug "Mail.smtpSend", "OK", transport.host, options.subject, "to #{options.to}", "from #{options.from}."
            callback err, result


    # INIT
    # --------------------------------------------------------------------------

    # Init the Mail module and create the SMTP objects.
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
    # @param [String] options The email message options
    # @option options [String] body The email body in text or HTML.
    # @option options [String] subject The email subject.
    # @option options [String] to The "to" address.
    # @option options [String] from The "from" address, optional, if blank use default from settings.
    # @param [Function] callback Callback (err, result) when message is sent or fails.
    send: (options, callback) ->
        if not smtp? and not smtp2?
            errMsg = "SMTP transport wasn't initiated. Abort!"
            logger.warn "Mail.send", errMsg, options
            return callback errMsg, null

        # Make sure message body is valid.
        if not options.body? or options.body is false or options.body is ""
            errMsg = "Option 'body' is not valid. Abort!"
            logger.warn "Mail.send", errMsg, options
            return callback errMsg, null

        # Make sure "to" address is valid.
        if not options.to? or options.to is false or options.to is ""
            errMsg = "Option 'to' is not valid. Abort!"
            logger.warn "Mail.send", errMsg, options
            return callback errMsg, null

        logger.debug "Mail.send", options

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

    # Load and return the specified template. Get from the cache or from the disk
    # if it wasn't loaded yet. Templates are stored inside the `/emailtemplates`
    # folder by default and should have a .html extension. The base template,
    # which is always loaded first, must be called base.html.
    # The contents will be inserted on the {contents} tag.
    # @param [String] name The template name, without .html.
    # @return [String] The template HTML.
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

    # Parse the specified template to replace keywords. The `keywords` is a set of key-values
    # to be replaced. For example if keywords is `{id: 1, friendlyUrl: "abc"}` then the tags
    # `{id}` and `{friendlyUrl}` will be replaced with the values 1 and abc.
    # @param [String] template The template (its value, not its name!) to be parsed.
    # @param [Object] keywords Object with keys to be replaced with its values.
    # @return [String] The parsed template, keywords replaced with values.
    parseTemplate: (template, keywords) =>
        template = template.toString()

        for key, value of keywords
            template = template.replace new RegExp("\\{#{key}\\}", "gi"), value

        return template


    # HELPER METHODS
    # --------------------------------------------------------------------------

    # Check if configuration for sending emails is properly set.
    checkConfig: =>
        if smtp or smtp2?
            return true
        else
            return false

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