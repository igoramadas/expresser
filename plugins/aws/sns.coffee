# AWS SNS
# -----------------------------------------------------------------------------
aws = require "aws-sdk"

errors = null
logger = null
settings = null

###
# Message delivery using AWS SNS.
###
class SNS

    # INIT
    # -------------------------------------------------------------------------

    ###
    # Init the AWS SNS module. Should be called automatically by the main AWS module.
    # @param {AWS} parent The AWS main module.
    # @private
    ###
    init: (parent) =>
        errors = parent.expresser.errors
        logger = parent.expresser.logger
        settings = parent.expresser.settings

        delete @init

    # METHODS
    # -------------------------------------------------------------------------

    ###
    # Publish a message to AWS SNS with the specified options.
    # @param {Object} options The SNS message options.
    # @param {String} [options.phoneNumber] The target phone number.
    # @param {String} [options.message] The SMS message to be sent.
    # @param {String} [options.region] The AWS region, if not passed will use default from settings.
    # @return {Object} AWS SDK SNS publish results.
    # @promise
    ###
    publish: (options) =>
        logger.debug "AWS.SNS.publish", options

        # Accept uppercased parameters as well, like in the AWS SDK.
        options.phoneNumber = options.PhoneNumber if not options.phoneNumber?
        options.message = options.Message if not options.message?

        return new Promise (resolve, reject) ->
            if not settings.aws.enabled
                return reject logger.notEnabled "AWS"

            sns = new aws.SNS {region: options.region or settings.aws.sns.region}

            if not options.phoneNumber? or options.phoneNumber is ""
                err = errors.reject "phoneRequired"
                logger.error "AWS.SNS.publish", err
                return reject err

            # Get last 4 digits oh phone to be logged.
            digits = "XXX" + options.phoneNumber.substr(options.phoneNumber.length - 4)

            params = {
                PhoneNumber: options.phoneNumber
                Message: options.message
            }

            # Dispatch the message.
            sns.publish params, (err, data) =>
                if err?
                    err = errors.reject "Error sending to #{digits}", err
                    logger.error "AWS.SNS.publish", err
                    reject err
                else
                    logger.info "AWS.SNS.publish", "#{options.message.length} chars published to #{digits}"
                    resolve data

# Singleton implementation
# -----------------------------------------------------------------------------
SNS.getInstance = ->
    @instance = new SNS() if not @instance?
    return @instance

module.exports = SNS.getInstance()
