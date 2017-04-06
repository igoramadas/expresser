# EXPRESSER AWS
# -----------------------------------------------------------------------------
# Module to use Amazon Web Services features on your app.
# <!--
# @see settings.aws
# -->
class AWS

    priority: 3

    aws = require "aws-sdk"
    fs = require "fs"
    path = require "path"

    events = null
    logger = null
    settings = null

    s3: require "./s3.coffee"
    sns: require "./sns.coffee"

    # INIT
    # -------------------------------------------------------------------------

    # Init the cron manager. If `loadOnInit` setting is true, the `cron.json`
    # file will be parsed and loaded straight away (if there's one).
    init: =>
        events = @expresser.events
        logger = @expresser.logger
        settings = @expresser.settings

        logger.debug "AWS.init"
        events.emit "AWS.before.init"

        # Init the implemented AWS modules.
        @s3.init this
        @sns.init this

        @setEvents()

        events.emit "AWS.on.init"
        delete @init

    # Bind events.
    setEvents: =>
        events.on "AWS.S3.download", @s3.download
        events.on "AWS.S3.upload", @s3.upload
        events.on "AWS.SNS.publish", @sns.publish

# Singleton implementation.
# -----------------------------------------------------------------------------
AWS.getInstance = ->
    @instance = new AWS() if not @instance?
    return @instance

module.exports = exports = AWS.getInstance()
