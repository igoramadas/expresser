# GOOGLE CLOUD: STORAGE
# -----------------------------------------------------------------------------
# Read and write data to the Google Cloud Storage.
class Storage

    gcloudStorage = require "@google-cloud/storage"

    logger = null
    settings = null

    # INIT
    # -------------------------------------------------------------------------

    # Init the Storage module.
    init: (parent) ->
        logger = parent.expresser.logger
        settings = parent.expresser.settings

        delete @init

    # IMPLEMENTATION
    # -------------------------------------------------------------------------

    # Get files from Google Storage.
    get: ->
        return

# Singleton implementation
# -----------------------------------------------------------------------------
Storage.getInstance = ->
    @instance = new Storage() if not @instance?
    return @instance

module.exports = exports = Storage.getInstance()
