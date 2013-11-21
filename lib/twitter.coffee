# EXPRESSER TWITTER
# --------------------------------------------------------------------------
# Handles communications with Twitter.
# Parameters on [settings.html](settings.coffee): Settings.Twitter

class Twitter

    lodash = require "lodash"
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
                setTimeout (() -> authenticate retry + 1), settings.twitter.retryInterval * 1000
            else
                logger.info "Twitter.init", "Authorized with ID #{data.id}."
                auth = true

    # Helper to check and log when the module hasn't authenticated or is not enabled.
    # This is called before any Twitter interaction.
    checkAuth = (title, msg) ->
        if not settings.twitter.enabled
            logger.warn "Expresser", title, "The Twitter module is not enabled!"
            return false
        if not auth
            logger.warn "Expresser", title, "Not authenticated!", msg
            return false

        # Enabled and authenticated, so return true.
        return true


    # INIT
    # --------------------------------------------------------------------------

    # Init the Twitter handler, but only if the consumer and access keys were
    # properly set on the [settings](settings.html).
    init: =>
        if settings.twitter.enabled

            consumerOk = settings.twitter.consumerKey? and settings.twitter.consumerSecret? and settings.twitter.consumerSecret isnt ""
            accessOk = settings.twitter.accessToken? and settings.twitter.accessSecret? and settings.twitter.accessSecret isnt ""

            if consumerOk and accessOk
                keys =
                    consumer_key: settings.twitter.consumerKey,
                    consumer_secret: settings.twitter.consumerSecret,
                    access_token_key: settings.twitter.accessToken,
                    access_token_secret: settings.twitter.accessSecret

                # Create the ntwitter object.
                twit = new twitter keys

                # Authenticate on Twitter.
                authenticate()

            else
                logger.debug "Twitter.init", "No credentials were set.", "Twitter module won't work."


    # STATUS
    # --------------------------------------------------------------------------

    # Post a status to the Twitter timeline. If a callback is passed,
    # it will get triggered with the corresponding status ID, or null if failed.
    postStatus: (message, callback) =>
        if not checkAuth "Twitter.postStatus", "Will NOT post status to Twitter."
            return

        # Update status on Twitter.
        twit.updateStatus message, (err, data) =>
            if err?
                logger.error "Twitter.postStatus", "Failed: #{message}", err
            else
                logger.debug "Twitter.postStatus", "Posted, ID #{data.id}: #{message}"
                callback err, data if callback?


    # MESSAGES
    # --------------------------------------------------------------------------

    # Send a direct message to the specified user on Twitter. If a `callback` is
    # specified, it will get triggered passing the sent message ID, or null if failed.
    sendMessage: (message, user, callback) =>
        if not checkAuth "Twitter.sendMessage", "Will NOT send message to #{user}."
            return

        # Send the message to the user.
        twit.sendDirectMessage {"screen_name": user, "text": message}, (err, data) =>
            if err?
                logger.error "Twitter.sendMessage", "Send to #{user} FAILED.", message, err
            else
                logger.debug "Twitter.sendMessage", "Sent to #{user}.", message
                callback err, data if callback?

    # Destroy the specified direct message. If a `callback` is specified, it will
    # get triggered passing true or false.
    destroyMessage: (id, callback) =>
        if not checkAuth "Twitter.destroyMessage", "Will NOT destroy message #{id}."
            return

        # Make a request to destroy the specified message.
        twit.destroyDirectMessage id, (err, data) =>
            if err?
                logger.error "Twitter.destroyMessage", "#{id} FAILED.", err
            else
                logger.debug "Twitter.destroyMessage", "#{id} SUCCESS."
                callback err, data if callback?

    # Returns a list of recent direct messages based on the optional `filter`, and process them
    # to generate new countdown models. A callback can be passed and will return an error
    # object (if any) and the messages result.
    getMessages: (filter, callback) =>
        if not checkAuth "Twitter.getMessages", "Will NOT get recent messages."
            return

        # If only one arguments is passed and it's a function, assume it's the callback.
        if not filter?
            filter = {}
        else if lodash.isFunction filter
            callback = filter

        # Make a request to get direct messages.
        twit.getDirectMessages filter, (err, data) =>
            if err?
                logger.error "Twitter.getMessages", "Could NOT retrieve direct messages.", err
            else
                logger.debug "Twitter.getMessages", "Retrieved #{data.length} messages."
                callback err, data if callback?


# Singleton implementation
# --------------------------------------------------------------------------
Twitter.getInstance = ->
    @instance = new Twitter() if not @instance?
    return @instance

module.exports = exports = Twitter.getInstance()