# EXPRESSER ERROR
# -----------------------------------------------------------------------------

###
# Contains error / exception helpers.
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
    ###
    @throw: (key, details) ->
        message = @messages[key] or key

        throw {error: message, details: details}

module.exports = Errors
