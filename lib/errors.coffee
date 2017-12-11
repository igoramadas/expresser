# EXPRESSER ERRORS
# -----------------------------------------------------------------------------

###
# This is a helper class to make it easier to keep error management and
# exception handling consistent across the app.
###
class Errors

    ##
    # List of common error messages. Can be changed and extended as you wish.
    # @property
    @messages: {
        expressNotInit: "Express app was not initialized yet, please use after app.init()."
    }

    ###
    # Throws an error.
    # @param {String} keyMsg Key of the message in `@messages`. If not found, use the string itself as the message. Mandatory.
    # @param {Object} details Object or exception containing more details about the error.
    ###
    @throw: (keyMsg, details) ->
        message = @messages[keyMsg] or keyMsg
        error = {error: message}
        error.details = details if details?
        throw error

# Exports
module.exports = Errors
