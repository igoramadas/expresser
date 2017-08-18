# AWS SNS
# -----------------------------------------------------------------------------
# Message delivery using AWS SNS.
class SNS

    aws = require "aws-sdk"
    fs = require "fs"

    logger = null
    settings = null
    sns = null

    # INIT
    # -------------------------------------------------------------------------

    # Init the SNS module.
    init: (parent) ->
        logger = parent.expresser.logger
        settings = parent.expresser.settings

        # Create the SNS handler.
        sns = new aws.SNS {region: settings.aws.sns.region}

        delete @init

    # METHODS
    # -------------------------------------------------------------------------

    # Publish a message with the specified options.
    # @param {String} options The SNS message options.
    # @option options {String} PhoneNumber The target phone number.
    # @option options {String} Message The SMS message to be sent.
    publish: (options) ->
        logger.debug "AWS.SNS.publish", options

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled("AWS", "SNS.publish")

            if not options.PhoneNumber? or options.PhoneNumber is ""
                ex = new Error "A PhoneNumber is required."
                logger.error "AWS.SNS.publish", ex
                return reject ex

            # Get last 4 digits oh phone to be logged.
            digits = "XXX" + options.PhoneNumber.substr(options.PhoneNumber.length - 4)

            # Dispatch the message.
            sns.publish options, (err, data) =>
                if err?
                    logger.error "AWS.SNS.publish", "Error sending to #{digits}", err, err.stack
                    reject err
                else
                    logger.info "AWS.SNS.publish", "Message published to #{digits}"
                    resolve data

# Singleton implementation
# -----------------------------------------------------------------------------
SNS.getInstance = ->
    @instance = new SNS() if not @instance?
    return @instance

module.exports = exports = SNS.getInstance()
