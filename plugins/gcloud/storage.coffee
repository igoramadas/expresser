# GOOGLE CLOUD: STORAGE
# -----------------------------------------------------------------------------
logger = null
settings = null

###
# Read and write data to the Google Cloud Storage.
###
class GCloudStorage

    ##
    # Exposes the actual Storage SDK to the outside.
    # @property
    sdk: require "@google-cloud/storage"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Storage module.
    init: (parent) =>
        logger = parent.expresser.logger
        settings = parent.expresser.settings

        delete @init

# Singleton implementation
# -----------------------------------------------------------------------------
GCloudStorage.getInstance = ->
    @instance = new GCloudStorage() if not @instance?
    return @instance

module.exports = exports = GCloudStorage.getInstance()
