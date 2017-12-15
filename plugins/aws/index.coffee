# EXPRESSER AWS
# -----------------------------------------------------------------------------
events = null
logger = null
settings = null

###
# Module to integrate your app with Amazon Web Services using the official AWS SDK module.
###
class AWS
    priority: 2

    ##
    # Exposes the actual AWS SDK to the outside.
    # @property
    # @see https://aws.amazon.com/sdk-for-node-js/
    @sdk: require "aws-sdk"

    ##
    # DynamoDB methods.
    # @property
    # @type {DynamoDB}
    @dynamodb: require "./dynamodb.coffee"

    ##
    # S3 methods.
    # @property
    # @type {S3}
    @s3: require "./s3.coffee"

    ##
    # SNS methods.
    # @property
    # @type {SNS}
    @sns: require "./sns.coffee"

    # INIT
    # -------------------------------------------------------------------------

    ###
    # Init the AWS plugin and load its sub modules.
    ###
    @init: ->
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

    ###
    # List to AWS events.
    # @private
    ###
    @setEvents: ->
        events.on "AWS.DynamoDB.createTable", @dynamodb.createTable
        events.on "AWS.DynamoDB.deleteTable", @dynamodb.deleteTable
        events.on "AWS.DynamoDB.scan", @dynamodb.scan
        events.on "AWS.DynamoDB.query", @dynamodb.query
        events.on "AWS.DynamoDB.get", @dynamodb.get
        events.on "AWS.DynamoDB.put", @dynamodb.put
        events.on "AWS.DynamoDB.update", @dynamodb.update
        events.on "AWS.DynamoDB.delete", @dynamodb.delete
        events.on "AWS.S3.download", @s3.download
        events.on "AWS.S3.upload", @s3.upload
        events.on "AWS.SNS.publish", @sns.publish

# Exports
# -----------------------------------------------------------------------------
module.exports = AWS
