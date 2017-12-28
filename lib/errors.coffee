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
        callbackMustBeFunction: "The callback must be a valid function."
        cantCreateDirectory: "Could not create directory."
        cantDeleteFile: "Could not delete file."
        cantSaveFile: "Could not save file."
        cantUploadFile: "Could not upload file."
        certificatesNotFound: "The specified certificates could not be found."
        domainRequired: "A valid domain is required."
        expressNotInit: "Express app was not initialized yet, please use after app.init()."
        invalidJson: "Invalid or unparseable JSON."
        moduleNotEnabled: "Module is not enabled."
        nameRequired: "A name is required."
        noNetworkInterfaces: "Could not load network interfaces info."
        pathRequired: "A valid path is required."
        phoneRequired: "A phone number is required."
        uniqueIdRequired: "ID is required and must be an unique value."
        tokenRequired: "A valid token is required."
        urlMandatory: "A URL is mandatory."
    }

    ###
    # Returns an error message as JSON using the format {error, details}.
    # @param {String} keyMsg Key of the message in `@messages`. If not found, use the string itself as the message. Mandatory.
    # @param {Object} details Object or exception containing more details about the error.
    # @return {Object} Returns the error with optional details.
    ###
    @reject: (keyMsg, details) ->
        message = @messages[keyMsg] or keyMsg
        error = {error: message}
        error.details = details if details?
        return error

    ###
    # Throws an error or exception using the format {error, details}.
    # @param {String} keyMsg Key of the message in `@messages`. If not found, use the string itself as the message. Mandatory.
    # @param {Object} details Object or exception containing more details about the error.
    ###
    @throw: (keyMsg, details) ->
        message = @messages[keyMsg] or keyMsg
        error = {error: message}
        error.details = details if details?
        throw error

# Exports
# -----------------------------------------------------------------------------
module.exports = Errors
