# EXPRESSER AWS
# -----------------------------------------------------------------------------
expresser = require "expresser"
events = expresser.events
logger = expresser.logger
settings = expresser.settings

###
# Module to integrate your app with Amazon Web Services using the official AWS SDK module.
###
class AWS

    priority: 2

    ##
    # Exposes the actual AWS SDK to the outside.
    # @property
    # @see https://aws.amazon.com/sdk-for-node-js/
    sdk: require "aws-sdk"

    ##
    # DynamoDB methods.
    # @property
    # @type DynamoDB
    dynamodb: require "./dynamodb.coffee"

    ##
    # S3 methods.
    # @property
    # @type S3
    s3: require "./s3.coffee"

    ##
    # SNS methods.
    # @property
    # @type SNS
    sns: require "./sns.coffee"

    # INIT
    # -------------------------------------------------------------------------

    ###
    # Init the AWS plugin and load its sub modules.
    ###
    init: =>
        logger.debug "AWS.init"
        events.emit "AWS.before.init"

        # Init the implemented AWS modules.
        @dynamodb.createClients()

        events.emit "AWS.on.init"
        delete @init

# Singleton implementation
# --------------------------------------------------------------------------
AWS.getInstance = ->
    @instance = new AWS() if not @instance?
    return @instance

module.exports = AWS.getInstance()
