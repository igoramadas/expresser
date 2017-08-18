# EXPRESSER GOOGLE CLOUD
# -----------------------------------------------------------------------------
# Integrate your app with Google Cloud services.
# <!--
# @see settings.gcloud
# -->
class GCloud

    priority: 2

    events = null
    logger = null
    settings = null

    datastore: require "./datastore"
    storage: require "./storage"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Google Cloud plugin
    init: ->
        events = @expresser.events
        logger = @expresser.logger
        settings = @expresser.settings

        logger.debug "GCloud.init"
        events.emit "GCloud.before.init"

        # Init the implemented Google Cloud modules.
        @datastore.init this
        @storage.init this

        @setEvents()

        events.emit "GCloud.on.init"
        delete @init

    # Bind events.
    setEvents: ->
        events.on "GCloud.Datastore.get", @datastore.get.bind(@datastore)

# Singleton implementation
# -----------------------------------------------------------------------------
GCloud.getInstance = ->
    @instance = new GCloud() if not @instance?
    return @instance

module.exports = exports = GCloud.getInstance()
