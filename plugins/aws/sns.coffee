# AWS SNS
# -----------------------------------------------------------------------------
aws = require "aws-sdk"
fs = require "fs"
errors = null
logger = null
settings = null
sns = null

###
# Message delivery using AWS SNS.
###
class SNS

    # INIT
    # -------------------------------------------------------------------------

    ###
    # Init the SNS module. Called automatically by the main main AWS module.
    # @param {AWS} parent The main AWS module.
    # @private
    ###
    @init: (parent) ->
        errors = parent.expresser.errors
        logger = parent.expresser.logger
        settings = parent.expresser.settings

        # Create the SNS handler.
        sns = new aws.SNS {region: settings.aws.sns.region}

        delete @init

    # METHODS
    # -------------------------------------------------------------------------

    ###
    # Publish a message to AWS SNS with the specified options.
    # @param {Object} options The SNS message options.
    # @param {String} [options.PhoneNumber] The target phone number.
    # @param {String} [options.Message] The SMS message to be sent.
    # @return {Object} AWS SDK SNS publish results.
    # @promise
    ###
    @publish: (options) ->
        logger.debug "AWS.SNS.publish", options

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled "AWS"

            if not options.PhoneNumber? or options.PhoneNumber is ""
                err = errors.reject "phoneRequired"
                logger.error "AWS.SNS.publish", err
                return reject err

            # Get last 4 digits oh phone to be logged.
            digits = "XXX" + options.PhoneNumber.substr(options.PhoneNumber.length - 4)

            # Dispatch the message.
            sns.publish options, (err, data) =>
                if err?
                    err = errors.reject "Error sending to #{digits}", err
                    logger.error "AWS.SNS.publish", err
                    reject err
                else
                    logger.info "AWS.SNS.publish", "Message published to #{digits}"
                    resolve data

# Exports
# -----------------------------------------------------------------------------
module.exports = SNS
