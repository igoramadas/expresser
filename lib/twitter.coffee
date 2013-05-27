# EXPRESSER TWITTER
# --------------------------------------------------------------------------
# Handles communications with Twitter.
# Parameters on [settings.html](settings.coffee): Settings.Twitter

class Twitter

    logger = require "./logger.coffee"
    moment = require "moment"
    settings = require "./settings.coffee"
    twitter = require "ntwitter"

    # The twitter handler.
    twit = null

    # Will be true only if it validates with the supplied the credentials.
    auth = false


    # INTERNAL FEATURES
    # -------------------------------------------------------------------------

    # Helper to authenticate on Twitter, with limited retries.
    authenticate = (retry) ->
        retry = 0 if not retry?

        # Verify if credentials are valid and set the `auth` variable.
        twit.verifyCredentials (err, data) =>
            # If fails, log and set a timeout to try again in a few seconds.
            if err?
                logger.warn "Expresser", "Twitter.init", "Can't verify credentials.", err
                auth = false
                setTimeout (() -> authenticate retry + 1), settings.Twitter.retryInterval * 1000
            else
                logger.info "Expresser", "Twitter.init", "Authorized with ID #{data.id}."
                auth = true


    # INIT
    # --------------------------------------------------------------------------

    # Init the Twitter handler, but only if the consumer and access keys were
    # properly set on the [settings](settings.html).
    init: =>
        if settings.Twitter.consumerSecret? and settings.Twitter.accessSecret? and settings.Twitter.accessSecret isnt ""
            keys =
                consumer_key: settings.Twitter.consumerKey,
                consumer_secret: settings.Twitter.consumerSecret,
                access_token_key: settings.Twitter.accessToken,
                access_token_secret: settings.Twitter.accessSecret

            # Create the ntwitter object.
            twit = new twitter keys

            # Authenticate on Twitter.
            authenticate()

        else if settings.General.debug
            logger.warn "Expresser", "Twitter.init", "No credentials were set.", "Twitter module won't work."


    # STATUS
    # --------------------------------------------------------------------------

    # Post a status to the Twitter timeline. If a callback is passed,
    # it will get triggered with the corresponding status ID, or null if failed.
    postStatus: (message, callback) =>
        if not auth
            @logNoAuth "Twitter.postStatus", "Will NOT post status to Twitter."
            return

        # Update status on Twitter.
        twit.updateStatus message, (err, data) =>
            if err?
                logger.error "Expresser", "Twitter.postStatus", "Failed: #{message}", err
            else if settings.General.debug
                logger.info "Expresser", "Twitter.postStatus", "Posted, ID #{data.id}: #{message}"


    # MESSAGES
    # --------------------------------------------------------------------------

    # Send a direct message to the specified user on Twitter. If a `callback` is
    # specified, it will get triggered passing the sent message ID, or null if failed.
    sendMessage: (message, user, callback) =>
        if not auth
            @logNoAuth "Twitter.sendMessage", "Will NOT send message to #{user}."
            return

        # Send the message to the user.
        twit.sendDirectMessage {"screen_name": user, "text": message}, (err, data) =>
            if err?
                callback null if callback?
                logger.error "Expresser", "Twitter.sendMessage", "Send to #{user} FAILED.", message, err
            else
                callback data.id if callback?
                if settings.General.debug
                    logger.info "Expresser", "Twitter.sendMessage", "Sent to #{user}.", message

    # Destroy the specified direct message. If a `callback` is specified, it will
    # get triggered passing true or false.
    destroyMessage: (id, callback) =>
        if not auth
            @logNoAuth "Twitter.destroyMessage", "Will NOT destroy message #{id}."
            return

        # Make a request to destroy the specified message.
        twit.destroyDirectMessage id, (err, data) =>
            if err?
                callback false if callback?
                logger.error "Expresser", "Twitter.destroyMessage", "#{id} FAILED.", err
            else
                callback true if callback?
                if settings.General.debug
                    logger.info "Expresser", "Twitter.destroyMessage", "#{id} SUCCESS."

    # Returns a list of recent direct messages based on the optional `filter`, and process them
    # to generate new countdown models. A callback can be passed and will return an error
    # object (if any) and the messages result.
    getMessages: (filter, callback) =>
        if not auth
            @logNoAuth "Twitter.getMessages", "Will NOT get recent messages."
            return

        # If only one arguments is passed and it's a function, assume it's the callback.
        if not filter?
            filter = {}
        else if typeof filter is "function"
            callback = filter

        # Make a request to get direct messages.
        twit.getDirectMessages filter, (err, data) =>
            if err?
                callback err, null if callback?
                logger.error "Expresser", "Twitter.getMessages", "Could NOT retrieve direct messages.", err
            else
                callback null, result if callback?
                if settings.General.debug
                    logger.info "Expresser", "Twitter.getMessages", "Retrieved #{data.length} messages."


    # HELPER METHODS
    # --------------------------------------------------------------------------

    # If `auth` is false and a request is made, log a warning saying it can't proceed.
    logNoAuth: (title, msg) =>
        if settings.General.debug
            logger.warn "Expresser", title, "Not authenticated!", msg
            return


# Singleton implementation
# --------------------------------------------------------------------------
Twitter.getInstance = ->
    @instance = new Twitter() if not @instance?
    return @instance

module.exports = exports = Twitter.getInstance()