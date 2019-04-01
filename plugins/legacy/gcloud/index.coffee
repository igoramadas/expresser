# EXPRESSER GOOGLE CLOUD
# -----------------------------------------------------------------------------
events = null
logger = null
settings = null

###
# Integrate your app with Google Cloud services.
###
class GCloud
    priority: 2

    ##
    # Google Cloud Datastore module.
    # @property
    # @type GCloudDatastore
    datastore: require "./datastore"

    ##
    # Google Cloud Storage module.
    # @property
    # @type GCloudStorage
    storage: require "./storage"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Google Cloud plugin
    init: =>
        events = @expresser.events
        logger = @expresser.logger
        settings = @expresser.settings

        logger.debug "GCloud.init"

        # Init the implemented Google Cloud modules.
        @datastore.init this
        @storage.init this

        events.emit "GCloud.on.init"
        delete @init

# Singleton implementation
# -----------------------------------------------------------------------------
GCloud.getInstance = ->
    @instance = new GCloud() if not @instance?
    return @instance

module.exports = exports = GCloud.getInstance()
