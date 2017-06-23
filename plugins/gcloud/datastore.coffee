# GOOGLE CLOUD: DATASTORE
# -----------------------------------------------------------------------------
# Read and write data to the Google Cloud Datastore.
class DataStore

    Datastore = require "@google-cloud/datastore"
    ds = null

    logger = null
    settings = null

    # INIT
    # -------------------------------------------------------------------------

    # Init the Datastore module.
    init: (parent) ->
        logger = parent.expresser.logger
        settings = parent.expresser.settings

        # Create the SNS handler.
        ds = Datastore {projectId: settings.app.id}

        delete @init

    # CRUD
    # -------------------------------------------------------------------------

    # Get records from the Datastore.
    get: (kind, options) ->
        options = options or {}

        q = ds.createQuery kind

        q = q.limit options.limit if options.limit?
        q = q.order options.order if options.order?
        q = q.start options.start if options.start?

        entities = await ds.runQuery q
        hasMore = false

        result = entities.map fromDs, hasMore

        return await result

    # HELPER METHODS
    # -------------------------------------------------------------------------

    # Transform data from Google's datastore.
    fromDs = (obj) ->
        obj.id = obj[Datastore.KEY].id
        return obj

    # Transform data to Google's datastore.
    toDs = (obj, nonIndexed) ->
        nonIndexed = nonIndexed or []
        results = []

        for key, value of obj
            return if not value?

            results.push {
                name: key
                value: value
                excludeFromIndexes: nonIndexed.indexOf(k) > -1
            }

        return results

# Singleton implementation
# -----------------------------------------------------------------------------
SNS.getInstance = ->
    @instance = new SNS() if not @instance?
    return @instance

module.exports = exports = SNS.getInstance()
