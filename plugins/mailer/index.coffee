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

    priority: 3

    events = null
    fs = require "fs"
    lodash = null
    logger = null
    moment = null
    nodemailer = require "nodemailer"
    path = require "path"
    settings = null
    utils = null

    # Templates manager.
    templates: require "./templates.coffee"

    # SMTP objects will be instantiated on `init`.
    smtp: null
    smtp2: null

    # INIT
    # --------------------------------------------------------------------------

    # Init the Mailer module and create the SMTP objects.
    init: =>
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        moment = @expresser.libs.moment
        settings = @expresser.settings
        utils = @expresser.utils

        logger.debug "Mailer.init"
        events.emit "Mailer.before.init"

        # Init the templates helper.
        @templates.init this

        # Define default primary SMTP.
        if settings.mailer.smtp.service? and settings.mailer.smtp.service isnt ""
            @setSmtp settings.mailer.smtp, false
        else if settings.mailer.smtp.host? and settings.mailer.smtp.host isnt "" and settings.mailer.smtp.port > 0
            @setSmtp settings.mailer.smtp, false

        # Define default secondary SMTP.
        if settings.mailer.smtp2.service? and settings.mailer.smtp2.service isnt ""
            @setSmtp settings.mailer.smtp2, true
        else if settings.mailer.smtp2.host? and settings.mailer.smtp2.host isnt "" and settings.mailer.smtp2.port > 0
            @setSmtp settings.mailer.smtp2, true

        @setEvents()

        events.emit "Mailer.on.init"
        delete @init

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
        return logger.notEnabled "Mailer", "send" if not settings.mailer.enabled

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
            template = @templates.get options.template
            html = @templates.parse template, {contents: html}

            # Parse template keywords if a `keywords` was passed.
            if lodash.isObject options.keywords
                html = @templates.parse html, options.keywords

        # Parse final template and set it on the `options`.
        html = @templates.parse html, {to: toName, appTitle: settings.app.title, appUrl: settings.app.url}
        options.html = html

        # Check if `doNotSend` flag is set, and if so, do not send anything.
        if settings.mailer.doNotSend
            return callback null, "The 'doNotSend' setting is true, will not send anything!" if callback?

        # Send using the main SMTP. If failed and a secondary is also set, try using the secondary.
        smtpSend smtp, options, (err, result) =>
            if err?
                if smtp2?
                    smtpSend smtp2, options, (err2, result2) -> callback err2, result2
                else
                    callback err, result if callback?
            else
                callback err, result if callback?

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
        return logger.notEnabled "Mailer", "createSmtp" if not settings.mailer.enabled

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

# Singleton implementation
# --------------------------------------------------------------------------
Mailer.getInstance = ->
    @instance = new Mailer() if not @instance?
    return @instance

module.exports = exports = Mailer.getInstance()
