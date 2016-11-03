# EXPRESSER MAILER
# --------------------------------------------------------------------------
# Sends and manages emails, with template and tags replacement support.
# When parsing templates, the tags should be wrapped with normal brackets {}.
# Example: {contents}
# The base message template (which is loaded with every single sent message)
# must be saved as base.html, under the /emailtemplates folder (or whatever
# folder / base file name you have set on the settings).
# <!--
# @see settings.mailer
# -->
class Mailer

    events = null
    fs = require "fs"
    lodash = null
    logger = null
    moment = null
    nodemailer = require "nodemailer"
    path = require "path"
    settings = null
    utils = null

    # SMTP objects will be instantiated on `init`.
    smtp: null
    smtp2: null

    # Templates cache to avoid disk reads.
    templateCache = {}

    # INIT
    # --------------------------------------------------------------------------

    # Init the Mailer module and create the SMTP objects.
    # @param {Object} options Mailer init options.
    init: (options) =>
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        moment = @expresser.libs.moment
        settings = @expresser.settings
        utils = @expresser.utils

        logger.debug "Mailer.init", options
        events.emit "Mailer.before.init"

        options = {} if not options?
        options = lodash.defaultsDeep options, settings.mailer

        if options.smtp.service? and options.smtp.service isnt ""
            @setSmtp options.smtp, false
        else if options.smtp.host? and options.smtp.host isnt "" and options.smtp.port > 0
            @setSmtp options.smtp, false

        if options.smtp2.service? and options.smtp2.service isnt ""
            @setSmtp options.smtp2, true
        else if options.smtp2.host? and options.smtp2.host isnt "" and options.smtp2.port > 0
            @setSmtp options.smtp2, true

        # Alert user if specified backup SMTP but not the main one.
        if not @smtp? and @smtp2?
            logger.warn "Mailer.init", "The secondary SMTP is defined but not the main one.", "You should set the main one instead, but we'll still use the secondary for now."

        # Warn if no SMTP is available for sending emails, but only when debug is enabled.
        if options.enabled and not @smtp? and not @smtp2?
            logger.warn "Mailer.init", "No default SMTP settings found.", "No emails will be sent out if you don't pass a SMTP server on `send`."

        @setEvents()

        events.emit "Mailer.on.init", options

    # Bind event listeners.
    setEvents: =>
        events.on "Mailer.send", @send

    # OUTBOUND
    # --------------------------------------------------------------------------

    # Sends an email to the specified address. A callback can be specified, having (err, result).
    # @param {String} options The email message options
    # @option options {String} body The email body in text or HTML.
    # @option options {String} subject The email subject.
    # @option options {String} to The "to" address.
    # @option options {String} from The "from" address, optional, if blank use default from settings.
    # @option options {String} template The template file to be loaded, optional.
    # @param {Method} callback Callback (err, result) when message is sent or fails.
    send: (options, callback) =>
        logger.debug "Mailer.send", options

        # Get passed SMTP servers or the default ones.
        smtp = options.smtp or @smtp
        smtp2 = options.smtp2 or @smtp2

        # Check if SMTP server is set.
        if not smtp? and not smtp2?
            err = new Error "Default SMTP transports were not initiated and nothing was passed on options.smtp."
            logger.error "Mailer.send", err, options
            throw err

        # Make sure "to" address is valid.
        if not options.to? or options.to is false or options.to is ""
            err = new Error "Option 'to' is mandatory and cannot be empty."
            logger.error "Mailer.send", err, options
            throw err

        # Set from to default address if no `to` was set.
        options.from = "#{settings.app.title} <#{settings.mailer.from}>" if not options.from?

        # Set HTML to body, if passed.
        html = if options.body? then options.body.toString() else ""

        # If to is an array, make it a string separated by commas.
        if lodash.isArray options.to
            options.to = options.to.join ", "

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
        html = @parseTemplate html, {to: toName, appTitle: settings.app.title, appUrl: settings.app.url}
        options.html = html

        # Check if `doNotSend` flag is set, and if so, do not send anything.
        if settings.mailer.doNotSend
            callback null, "The 'doNotSend' setting is true, will not send anything!" if callback?
            return

        # Send using the main SMTP. If failed and a secondary is also set, try using the secondary.
        smtpSend smtp, options, (err, result) =>
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
    # @param {String} name The template name, without .html.
    # @return {String} The template HTML.
    getTemplate: (name) =>
        name = name.toString()
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
        templateCache[name].expires = moment().add settings.general.ioCacheTimeout, "s"

        return result

    # Parse the specified template to replace keywords. The `keywords` is a set of key-values
    # to be replaced. For example if keywords is `{id: 1, friendlyUrl: "abc"}` then the tags
    # `{id}` and `{friendlyUrl}` will be replaced with the values 1 and abc.
    # @param {String} template The template (its value, not its name!) to be parsed.
    # @param {Object} keywords Object with keys to be replaced with its values.
    # @return {String} The parsed template, keywords replaced with values.
    parseTemplate: (template, keywords) =>
        logger.debug "Mailer.parseTemplate", template, keywords

        template = template.toString()

        for key, value of keywords
            template = template.replace new RegExp("\\{#{key}\\}", "gi"), value

        return template

    # SMTP HELPER METHODS
    # --------------------------------------------------------------------------

    # Helper to send emails using the specified transport and options.
    # This is NOT exposed to external modules.
    smtpSend = (transport, options, callback) ->
        try
            transport.sendMail options, (err, result) ->
                logger.debug "Mailer.smtpSend", "OK", transport.host, options.subject, "to #{options.to}", "from #{options.from}."
                callback err, result
        catch ex
            callback ex

    # Helper to create a SMTP object.
    # @param {Object} options Options like service, host and port, username, password etc.
    # @return {Object} A Nodemailer SMTP transport object, or null if a problem was found.
    createSmtp: (options) ->
        logger.debug "Mailer.createSmtp", options

        options.debug = settings.general.debug if not options.debug?
        options.secureConnection = options.secure if not options.secureConnection?
        dkim = options.dkim or settings.mailer.dkim

        # Make sure auth is properly set.
        if not options.auth? and options.user? and options.password?
            options.auth = {user: options.user, pass: options.password}
            delete options["user"]
            delete options["password"]

        # Set the correct SMTP details based on the options.
        result = nodemailer.createTransport options

        # Sign using DKIM?
        if dkim.domainName? and dkim.privateKey?
            result.useDKIM dkim

        return result

    # Use the specified options and create a new SMTP server.
    # @param {Object} options Options to be passed to SMTP creator.
    # @param {Boolean} secondary If false set as the main SMTP server, if true set as secondary.
    setSmtp: (options, secondary) =>
        if not secondary or secondary < 1
            @smtp = @createSmtp options
        else
            @smtp2 = @createSmtp options

    # CACHE METHODS
    # --------------------------------------------------------------------------

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
