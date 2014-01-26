# EXPRESSER MAILER
# --------------------------------------------------------------------------
# Sends and manages emails, supports templates. When parsing templates, the
# tags should be wrapped with normal brackets {}. Example: {contents}
# The base message template (which is loaded with every single sent message)
# must be saved as base.html, under the /emailtemplates folder (or whatever
# folder / base file name you have set on the settings).
# <!--
# @see Settings.mail
# -->
class Mailer

    events = require "./events.coffee"
    fs = require "fs"
    lodash = require "lodash"
    logger = require "./logger.coffee"
    mailer = require "nodemailer"
    moment = require "moment"
    path = require "path"
    settings = require "./settings.coffee"
    utils = require "./utils.coffee"

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
        events.on "mailer.send", @send

    # Init the Mailer module and create the SMTP objects.
    # Also check if still using old "mail" instead of "mailer".
    # TODO! Old .mail references should be removed in April 2014.
    init: =>
        if settings.mail?
            settings.mailer = lodash.defaults settings.mail, settings.mailer
            logger.warn "Mailer.init", "The module is now called Mailer, please update settings from 'mail' to 'mailer'."

        # Check and set main SMTP.
        if settings.mailer.smtp.service? and settings.mailer.smtp.service isnt ""
            @setSmtp settings.mailer.smtp, false
        else if settings.mailer.smtp.host? and settings.mailer.smtp.host isnt "" and settings.mailer.smtp.port > 0
            @setSmtp settings.mailer.smtp, false

        # Check and set secondary SMTP.
        if settings.mailer.smtp2.service? and settings.mailer.smtp2.service isnt ""
            @setSmtp settings.mailer.smtp2, true
        else if settings.mailer.smtp2.host? and settings.mailer.smtp2.host isnt "" and settings.mailer.smtp2.port > 0
            @setSmtp settings.mailer.smtp2, true

        # Warn if no SMTP is available for sending emails, but only when debug is enabled.
        if not smtp? and not smtp2? and settings.general.debug
            logger.warn "Mailer.init", "No main SMTP host/port specified.", "No emails will be sent out!"

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
    # @option options [String] template The template file to be loaded, optional.
    # @param [Function] callback Callback (err, result) when message is sent or fails.
    send: (options, callback) =>
        logger.debug "Mailer.send", options

        if not @checkConfig()
            errMsg = "SMTP transport wasn't initiated. Abort!"
            logger.warn "Mailer.send", errMsg, options
            callback errMsg, null if callback?
            return

        # Make sure "to" address is valid.
        if not options.to? or options.to is false or options.to is ""
            errMsg = "Option 'to' is not valid. Abort!"
            logger.warn "Mailer.send", errMsg, options
            callback errMsg, null if callback?
            return

        # Set from to default address if no `to` was set, and `logError` defaults to true.
        options.from = "#{settings.general.appTitle} <#{settings.mailer.from}>" if not options.from?
        options.logError = true if not options.logError?

        # Set HTML to body, if passed.
        html = if options.body? then options.body.toString() else ""

        # Get the name of recipient based on the `to` option.
        if options.to.indexOf("<") < 3
            toName = options.to
        else
            toName = options.to.substring 0, options.to.indexOf("<") - 1

        # Load template if a `template` was passed.
        if options.template? and options.template isnt ""
            template = @getTemplate options.template
            html = @parseTemplate template, {contents: html}

            # Parse template keywords if a `keywords` was passed.
            if lodash.isObject options.keywords
                html = @parseTemplate html, options.keywords

        # Parse final template and set it on the `options`.
        html = @parseTemplate html, {to: toName, appTitle: settings.general.appTitle, appUrl: settings.general.appUrl}
        options.html = html

        # Send using the main SMTP. If failed and a secondary is also set, try using the secondary.
        smtpSend smtp, options, (err, result) ->
            if err?
                if smtp2?
                    smtpSend smtp2, options, (err2, result2) -> callback err2, result2
                else
                    callback err, result if callback?
            else
                callback err, result if callback?

    # TEMPLATES
    # --------------------------------------------------------------------------

    # Load and return the specified template. Get from the cache or from the disk
    # if it wasn't loaded yet. Templates are stored inside the `/emailtemplates`
    # folder by default and should have a .html extension. The base template,
    # which is always loaded first, should be called base.html by default.
    # The contents will be inserted on the {contents} tag.
    # @param [String] name The template name, without .html.
    # @return [String] The template HTML.
    getTemplate: (name) =>
        name = name.replace(".html", "") if name.indexOf(".html")

        cached = templateCache[name]

        # Is it already cached? If so do not hit the disk.
        if cached? and cached.expires > moment()
            logger.debug "Mailer.getTemplate", name, "Loaded from cache."
            return templateCache[name].template
        else
            logger.debug "Mailer.getTemplate", name

        # Set file system reading options.
        readOptions = {encoding: settings.general.encoding}
        baseFile = utils.getFilePath path.join(settings.path.emailTemplatesDir, settings.mailer.baseTemplateFile)
        templateFile = utils.getFilePath path.join(settings.path.emailTemplatesDir, "#{name}.html")

        # Read base and `name` template and merge them together.
        base = fs.readFileSync baseFile, readOptions
        template = fs.readFileSync templateFile, readOptions
        result = @parseTemplate base, {contents: template}

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
                    logger.error "Mailer.smtpSend", transport.host, "Could not send: #{options.subject} to #{options.to}.", err
            else
                logger.debug "Mailer.smtpSend", "OK", transport.host, options.subject, "to #{options.to}", "from #{options.from}."
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
            logger.info "Mailer.createSmtp", "Service", options.service
            result = mailer.createTransport options.service, options
        else
            logger.info "Mailer.createSmtp", options.host, options.port, options.secureConnection
            result = mailer.createTransport "SMTP", options

        # Sign using DKIM?
        result.useDKIM settings.mailer.dkim if settings.mailer.dkim.enabled

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
        logger.info "Mailer.clearCache", "Cleared #{count} templates."


# Singleton implementation
# --------------------------------------------------------------------------
Mailer.getInstance = ->
    @instance = new Mailer() if not @instance?
    return @instance

module.exports = exports = Mailer.getInstance()