# EXPRESSER DATABASE - MONGODB
# -----------------------------------------------------------------------------
# Handles MongoDB database transactions using the `mongoskin` module. It supports
# a very simple failover mechanism where you can specify a "backup" connection
# string to which the module will connect in case the main database is down.
# If you prefer tp access Mongo directly, you can use the `db` property, for example:
# expresser.database.db.collection("mycollection").findAndModify(args...).
# <!--
# @see Settings.database.mongo
# -->
class DatabaseMongo

    lodash = null
    logger = null
    settings = null

    # Mongoskin object, set on init.
    mongoskin = require "mongoskin"

    # INIT
    # -------------------------------------------------------------------------

    # Init the database module and test the connection straight away.
    # @param [Object] options Database init options.
    init: (options) =>
        database = @expresser.database
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        settings = @expresser.settings

        database.drivers.mongo = this

        logger.debug "DatabaseMongo.init", options
        lodash.assign settings.database.mongo, options if options?

        if settings.database.mongo.connString? and settings.database.mongo.connString isnt ""
            database.register "mongo", "mongo", settings.database.mongo.connString, settings.database.mongo.options

    # Set the current DB object. Can be called externally but ideally you should control
    # the connection string by updating your app settings.json file.
    # @param [Object] connString The connection string, for example user:password@hostname/dbname.
    # @param [Object] options Additional options to be passed when creating the DB connection object.
    setDb: (connString, options) =>
        sep = connString.indexOf "@"
        connStringSafe = connString
        connStringSafe = connStringSafe.substring sep if sep > 0
        logger.debug "DatabaseMongo.setDb", connStringSafe, options

        return mongoskin.db connString, options

    # HELPERS
    # -------------------------------------------------------------------------

    # Helper to transform MongoDB document "_id" to "id".
    # @param [Object] result The document or result to be normalized.
    # @return [Object] Returns the normalized document.
    normalizeId = (result) ->
        return if not result?

        isArray = lodash.isArray result or lodash.isArguments result

        # Check if result is a collection / array or a single document.
        if isArray
            for obj in result
                if obj["_id"]?
                    obj["id"] = obj["_id"].toString()
                    delete obj["_id"]
        else if result["_id"]?
            result["id"] = result["_id"].toString()
            delete result["_id"]

        return result

    # CRUD IMPLEMENTATION
    # -------------------------------------------------------------------------

    # Get data from the database. A `collection` and `callback` must be specified. The `filter` is optional.
    # Please note that if `filter` has an _id or id field, or if it's a plain string or number, it will be used
    # to return documents by ID. Otherwise it's used as keys-values object for filtering.
    # @param [String] collection The collection name.
    # @param [String, Object] filter Optional, if a string or number, assume it's the document ID. Otherwise assume keys-values filter.
    # @param [Object] options Options to be passed to the query.
    # @option options [Integer] limit Limits the resultset to X documents.
    # @param [Method] callback Callback (err, result) when operation has finished.
    get: (collection, filter, options, callback) ->
        if not callback?
            if lodash.isFunction options
                callback = options
                options = null
            else if lodash.isFunction filter
                callback = filter
                filter = null

        # Callback is mandatory!
        if not callback?
            throw new Error "DatabaseMongo.get: a callback (last argument) must be specified."

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                result = normalizeId result if settings.database.normalizeId
                callback err, result

        # Set collection object.
        dbCollection = @collection collection

        # Parse ID depending on `filter`.
        if filter?
            if filter._id?
                id = filter._id
            else if filter.id? and settings.database.normalizeId
                id = filter.id
            else
                t = typeof filter
                id = filter if t is "string" or t is "integer"

        # Get `limit` option.
        if options?.limit?
            limit = options.limit
        else
            limit = 0

        # Find documents depending on `filter` and `options`.
        # If id is set, use the shorter findById.
        if id?
            dbCollection.findById id, dbCallback

        # Create a params object for the find method.
        else if filter?
            findParams = {$query: filter}
            findParams["$orderby"] = options.orderBy if options?.orderBy?

            if limit > 0
                dbCollection.find(findParams).limit(limit).toArray dbCallback
            else
                dbCollection.find(findParams).toArray dbCallback

        # Search everything!
        else
            if limit > 0
                dbCollection.find({}).limit(limit).toArray dbCallback
            else
                dbCollection.find({}).toArray dbCallback

        if filter?
            filterLog = filter
            filterLog.password = "***" if filterLog.password?
            filterLog.passwordHash = "***" if filterLog.passwordHash?
            logger.debug "DatabaseMongo.get", collection, filterLog, options
        else
            logger.debug "DatabaseMongo.get", collection, "No filter.", options

    # Add new documents to the database.
    # The `options` parameter is optional.
    # @param [String] collection The collection name.
    # @param [Object] obj Document or array of documents to be added.
    # @param [Method] callback Callback (err, result) when operation has finished.
    insert: (collection, obj, callback) ->
        if not obj?
            if callback?
                callback "DatabaseMongo.insert: no object (second argument) was specified."
            return false

        # No DB set? Throw exception.
        if not db?
            if callback?
                callback "DatabaseMongo.insert: the db was not initialized, please check database settings and call its 'init' method."
            return false

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                result = normalizeId(result) if settings.database.normalizeId
                callback err, result

        # Set collection object.
        dbCollection = @collection collection

        # Execute insert!
        dbCollection.insert obj, dbCallback
        logger.debug "DatabaseMongo.insert", collection

    # Update existing documents on the database.
    # The `options` parameter is optional.
    # @param [String] collection The collection name.
    # @param [Object] obj Document or data to be updated.
    # @param [Object] options Optional, options to control and filter the insert behaviour.
    # @option options [Object] filter Defines the query filter. If not specified, will try using the ID of the passed object.
    # @option options [Boolean] patch Default is false, if true replace only the specific properties of documents instead of the whole data, using $set.
    # @option options [Boolean] upsert Default is false, if true it will create documents if none was found.
    # @param [Method] callback Callback (err, result) when operation has finished.
    update: (collection, obj, options, callback) ->
        if not callback? and lodash.isFunction options
            callback = options
            options = {}

        # Object or filter is mandatory.
        if not obj?
            if callback?
                callback "DatabaseMongo.update: no object (second argument) was specified."
            return false

        # No DB set? Throw exception.
        if not db?
            if callback?
                callback "DatabaseMongo.update: the db was not initialized, please check database settings and call its 'init' method."
            return false

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                result = normalizeId(result) if settings.database.normalizeId
                callback err, result

        # Set collection object.
        dbCollection = @collection collection

        # Make sure the ID is converted to ObjectID.
        if obj._id?
            id = mongoskin.ObjectID.createFromHexString obj._id.toString()
        else if obj.id? and settings.database.normalizeId
            id = mongoskin.ObjectID.createFromHexString obj.id.toString()

        # Make sure options is valid.
        options = {} if not options?

        # If a `filter` option was set, use it as the query filter otherwise use the "_id" property.
        if options.filter?
            filter = options.filter
        else
            filter = {_id: id}
        delete options.filter

        # If options patch is set, replace specified document properties only instead of replacing the whole document.
        if options.patch
            docData = {$set: obj}
        else
            docData = obj
        delete options.patch

        # Set default options.
        options = lodash.defaults options, {upsert: false, multi: true}

        # Execute update!
        dbCollection.update filter, docData, options, dbCallback

        if id?
            logger.debug "DatabaseMongo.update", collection, options, "ID: #{id}"
        else
            logger.debug "DatabaseMongo.update", collection, options, "New document."

    # Delete an object from the database. The `obj` argument can be either the document itself, or its integer/string ID.
    # @param [String] collection The collection name.
    # @param [String, Object] filter If a string or number, assume it's the document ID. Otherwise assume the document itself.
    # @param [Method] callback Callback (err, result) when operation has finished.
    remove: (collection, filter, callback) ->
        if not callback? and lodash.isFunction options
            callback = options
            options = {}

        # Filter is mandatory.
        if not filter?
            if callback?
                callback "DatabaseMongo.remove: no filter (second argument) was specified."
            return false

        # Check it the `obj` is the model itself, or only the ID string / number.
        if filter._id?
            id = filter._id
        else if filter.id and settings.database.normalizeId
            id = filter.id
        else
            t = typeof filter
            id = filter if t is "string" or t is "integer"

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                result = normalizeId(result) if settings.database.normalizeId
                callback err, result

        # Set collection object and remove specified object from the database.
        dbCollection = @collection collection

        # Remove object by ID or filter.
        if id? and id isnt ""
            dbCollection.removeById id, dbCallback
        else
            dbCollection.remove filter, dbCallback

        logger.debug "DatabaseMongo.remove", collection, filter

    # Count documents from the database. A `collection` must be specified.
    # If no `filter` is not passed then count all documents.
    # @param [String] collection The collection name.
    # @param [Object] filter Optional, keys-values filter of documents to be counted.
    # @param [Method] callback Callback (err, result) when operation has finished.
    count: (collection, filter, callback) ->
        if not callback? and lodash.isFunction filter
            callback = filter
            filter = {}

        # Callback is mandatory!
        if not callback?
            throw new Error "DatabaseMongo.count: a callback (last argument) must be specified."

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                logger.debug "DatabaseMongo.count", collection, filter, "Result #{result}"
                callback err, result

        # MongoDB has a built-in count so use it.
        dbCollection = @collection collection
        dbCollection.count filter, dbCallback

# Singleton implementation.
# -----------------------------------------------------------------------------
DatabaseMongo.getInstance = ->
    @instance = new DatabaseMongo() if not @instance?
    return @instance

module.exports = exports = DatabaseMongo.getInstance()
