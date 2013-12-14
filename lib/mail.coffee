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

    events = require "./events.coffee"
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


    # CONSTRUCTOR AND INIT
    # --------------------------------------------------------------------------

    # Class constructor.
    constructor: ->
        @setEvents()

    # Bind event listeners.
    setEvents: =>
        events.on "mail.send", @send

    # Init the Mail module and create the SMTP objects.
    init: =>
        if settings.mail.smtp.service? and settings.mail.smtp.service isnt ""
            @setSmtp settings.mail.smtp, false
        else if settings.mail.smtp.host? and settings.mail.smtp.host isnt "" and settings.mail.smtp.port > 0
            @setSmtp settings.mail.smtp, false

        if settings.mail.smtp2.service? and settings.mail.smtp2.service isnt ""
            @setSmtp settings.mail.smtp2, true
        else if settings.mail.smtp2.host? and settings.mail.smtp2.host isnt "" and settings.mail.smtp2.port > 0
            @setSmtp settings.mail.smtp2, true

        # Warn if no SMTP is available for sending emails, but only when debug is enabled.
        if not smtp? and not smtp2? and settings.general.debug
            logger.warn "Mail.init", "No main SMTP host/port specified.", "No emails will be sent out!"

    # Check if configuration for sending emails is properly set.
    checkConfig: =>
        if smtp or smtp2?
            return true
        else
            return false


    # OUTBOUND
    # --------------------------------------------------------------------------

    # Sends an email to the specified address. A callback can be specified, having (err, result).
    # @param [String] options The email message options
    # @option options [String] body The email body in text or HTML.
    # @option options [String] subject The email subject.
    # @option options [String] to The "to" address.
    # @option options [String] from The "from" address, optional, if blank use default from settings.
    # @param [Function] callback Callback (err, result) when message is sent or fails.
    send: (options, callback) =>
        if not @checkConfig()
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

        # Set from to default address if no `to` was set, and `logError` defaults to true.
        options.from = "#{settings.general.appTitle} <#{settings.mail.from}>" if not options.from?
        options.logError = true if not options.logError?

        # Debug log.
        logger.debug "Mail.send", options

        # Get the name of recipient based on the `to` option.
        if options.to.indexOf("<") < 3
            toName = options.to
        else
            toName = options.to.substring 0, options.to.indexOf("<") - 1

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

    # Helper to send emails using the specified transport and options.
    smtpSend = (transport, options, callback) ->
        transport.sendMail options, (err, result) ->
            if err?
                if options.logError
                    logger.error "Mail.smtpSend", transport.host, "Could not send: #{options.subject} to #{options.to}.", err
            else
                logger.debug "Mail.smtpSend", "OK", transport.host, options.subject, "to #{options.to}", "from #{options.from}."
            callback err, result

    # Helper to create a SMTP object.
    createSmtp = (options) ->
        options.debug = settings.general.debug if not options.debug?
        options.secureConnection = options.secure if not options.secureConnection?

        # Make sure auth is properly set.
        if not options.auth? and options.user? and options.password?
            options.auth = {user: options.user, pass: options.password}
            delete options["user"]
            delete options["password"]

        # Check if `service` is set. If so, pass to the mailer, otheriwse use SMTP.
        if options.service? and options.service isnt ""
            logger.info "Mail.createSmtp", "Service", options.service
            result = mailer.createTransport options.service, options
        else
            logger.info "Mail.createSmtp", options.host, options.port, options.secureConnection
            result = mailer.createTransport "SMTP", options

        # Sign using DKIM?
        result.useDKIM settings.mail.dkim if settings.mail.dkim.enabled

        # Return SMTP object.
        return result

    # Use the specified options and create a new SMTP server.
    # @param [Object] options Options to be passed to SMTP creator.
    # @param [Boolean] secondary If false set as the main SMTP server, if true set as secondary.
    setSmtp: (options, secondary) =>
        if secondary or secondary > 0
            smtp2 = createSmtp options
        else
            smtp = createSmtp options

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