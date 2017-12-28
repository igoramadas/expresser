# EXPRESSER AWS
# -----------------------------------------------------------------------------
events = null
logger = null
settings = null

###
# Module to integrate your app with Amazon Web Services using the official AWS SDK module.
# As of now it implements helpers for DynamoDB, S3 and SNS, but you can use any of the
# AWS SDK features by accessing the `sdk` of this module directly.
#
# Please see https://aws.amazon.com/sdk-for-node-js/ for the AWS SDK docs.
###
class AWS
    priority: 2

    ##
    # Exposes the actual AWS SDK to the outside.
    # @property
    # @type AWS-SDK
    sdk: require "aws-sdk"

    ##
    # DynamoDB module.
    # @property
    # @type DynamoDB
    dynamodb: require "./dynamodb.coffee"

    ##
    # S3 module.
    # @property
    # @type S3
    s3: require "./s3.coffee"

    ##
    # SNS module.
    # @property
    # @type SNS
    sns: require "./sns.coffee"

    # INIT
    # -------------------------------------------------------------------------

    ###
    # Init the AWS plugin and load its sub modules. Should be called automatically
    # by the main Expresser module.
    # @private
    ###
    init: =>
        events = @expresser.events
        logger = @expresser.logger
        settings = @expresser.settings

        logger.debug "AWS.init"

        # Init the implemented AWS modules.
        @dynamodb.init this
        @s3.init this
        @sns.init this

        events.emit "AWS.on.init"
        delete @init

# Singleton implementation
# -----------------------------------------------------------------------------
AWS.getInstance = ->
    @instance = new AWS() if not @instance?
    return @instance

module.exports = AWS.getInstance()
