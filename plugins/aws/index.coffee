# EXPRESSER AWS
# -----------------------------------------------------------------------------
# Module to integrate your app with Amazon Web Services.
# <!--
# @see settings.aws
# -->
class AWS

    priority: 2

    aws = require "aws-sdk"
    fs = require "fs"
    path = require "path"

    events = null
    logger = null
    settings = null

    dynamodb: require "./dynamodb.coffee"
    s3: require "./s3.coffee"
    sns: require "./sns.coffee"

    # INIT
    # -------------------------------------------------------------------------

    # Init the AWS plugin.
    init: ->
        events = @expresser.events
        logger = @expresser.logger
        settings = @expresser.settings

        logger.debug "AWS.init"
        events.emit "AWS.before.init"

        # Init the implemented AWS modules.
        @dynamodb.init this
        @s3.init this
        @sns.init this

        @setEvents()

        events.emit "AWS.on.init"
        delete @init

    # Bind events.
    setEvents: ->
        events.on "AWS.S3.download", @s3.download
        events.on "AWS.S3.upload", @s3.upload
        events.on "AWS.SNS.publish", @sns.publish

# Singleton implementation
# -----------------------------------------------------------------------------
AWS.getInstance = ->
    @instance = new AWS() if not @instance?
    return @instance

module.exports = exports = AWS.getInstance()
