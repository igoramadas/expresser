# GOOGLE CLOUD: DATASTORE
# -----------------------------------------------------------------------------
# Read and write data to the Google Cloud Datastore.
class Datastore

    gcloudDatastore = require "@google-cloud/datastore"
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
        ds = gcloudDatastore {projectId: settings.app.id}

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

        # Query the Datastore!
        try
            query = await ds.runQuery q
            endCursor = if query.moreResults isnt Datastore.NO_MORE_RESULTS then query.endCursor else false
            entities = query[0].map fromDs
        catch ex
            logger.error "GCloud.Datastore.get", kind, options, ex
            throw ex

        result = {entities: entities, endCursor: endCursor}

        return await result

    # Create / update records on the Datastore.
    upsert = (kind, id, data) ->
        if id?
            key = ds.key [kind, parseInt(id, 10)]
        else
            key = ds.key kind

        # Create entity object to be sent out.
        entity = {
            key: key
            data: toDs data, ["description"]
        }

        # Try saving the entity to the Datastore.
        try
            result = await ds.save entity
            data.id = entity.key.id
        catch ex
            logger.error "GCloud.Datastore.upsert", kind, ex
            throw ex

        return await result

    # Remove (delete) a record from the Datastore.
    remove: (kind, id) ->
        try
            key = ds.key [kind, parseInt(id, 10)]
            result = await ds.delete key
        catch ex
            logger.error "GCloud.Datastore.remove", kind, id, ex
            throw ex

        return await result

    # HELPER METHODS
    # -------------------------------------------------------------------------

    # Transform data from Google's datastore.
    fromDs = (obj) ->
        obj.id = obj[gcloudDatastore.KEY].id
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
Datastore.getInstance = ->
    @instance = new Datastore() if not @instance?
    return @instance

module.exports = exports = Datastore.getInstance()
