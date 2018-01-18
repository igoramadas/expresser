# EXPRESSER MONGODB
# -----------------------------------------------------------------------------
lodash = null
logger = null
settings = null

###
# Handles MongoDB database transactions using the native `mongodb` module.
###
class MongoDb
    priority: 2

    ##
    # The MongoDB official client.
    # @property
    client: require("mongodb").MongoClient

    ##
    # Collection holding all connected databases.
    # @property
    # @type Array
    connections: []

    # INIT
    # -------------------------------------------------------------------------

    ###
    # Init the MongoDB database module.
    # @return {Object} Returns the MongoDB connection created (only if default settings are set).
    ###
    init: =>
        database = @expresser.database
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        settings = @expresser.settings

        logger.debug "MongoDb.init"

        events.emit "MongoDb.on.init"
        delete @init

    ###
    # Get the DB connection object.
    # @param {Object} connString The connection string, for example user:password@hostname/dbname.
    # @param {Object} options Additional options to be passed when creating the DB connection object.
    # @return {Object} The database connection object.
    # @promise
    ###
    connect: (connString, options) =>
        logger.debug "MongoDb.connect", connString, options

        if not settings.mongodb.enabled
            return logger.notEnabled "MongoDb"

        connStringSafe = connString
        sep = connString.indexOf "@"
        connStringSafe = connStringSafe.substring sep if sep > 0
        sep = connString.indexOf "/"
        connStringSafe = connStringSafe.substring 0, sep if sep > 0

        # Tries to connect to the specified database.
        return new Promise (resolve, reject) =>
            result = {connString: connString, connection: null}

            # Connection string is mandatory!
            if not connString? or connString is ""
                return reject {error: "Connection string not set."}

            @client.connect connString, options, (err, conn) =>
                if err?
                    logger.error "MongoDb.getConnection", "Could not connect to #{connStringSafe}.", err

                    reject err
                else
                    logger.info "MongoDb.getConnection", "Connected to #{connStringSafe}"
                    result.connection = conn
                    result.get = @get
                    result.insert = @insert
                    result.update = @update
                    result.remove = @remove
                    result.count = @count

                    resolve result

    # MAIN METHODS
    # -------------------------------------------------------------------------

    ###
    # Get data from the database. A `collection` and `callback` must be specified. The `filter` is optional.
    # Please note that if `filter` has an _id or id field, or if it's a plain string or number, it will be used
    # to return documents by ID. Otherwise it's used as keys-values object for filtering.
    # @param {String} collection The collection name.
    # @param {Object} filter Optional, if a string or number, assume it's the document ID. Otherwise assume keys-values filter.
    # @param {Object} options Options to be passed to the query.
    # @param {Number} [options.limit] Limits the resultset to X documents.
    # @param {Function} callback Callback (err, result) when operation has finished.
    ###
    get: (collection, filter, options, callback) ->
        if not callback?
            if lodash.isFunction options
                callback = options
                options = null
            else if lodash.isFunction filter
                callback = filter
                filter = null

        if not @connection?
            throw new Error "MongoDb.get: the db was not initialized, please check database settings and call its 'init' method."

        # Callback is mandatory!
        if not callback?
            throw new Error "MongoDb.get: a callback (last argument) must be specified."

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                callback err, result

        # Set collection object.
        dbCollection = @connection.collection collection

        # Parse ID depending on `filter`.
        if filter?
            if filter._id?
                id = filter._id
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
            logger.debug "MongoDb.get", collection, filterLog, options
        else
            logger.debug "MongoDb.get", collection, "No filter.", options

    ###
    # Add new documents to the database.
    # The `options` parameter is optional.
    # @param {String} collection The collection name.
    # @param {Object} obj Document or array of documents to be added.
    # @param {Function} callback Callback (err, result) when operation has finished.
    ###
    insert: (collection, obj, callback) ->
        if not @connection?
            throw new Error "MongoDb.insert: the db was not initialized, please check database settings and call its 'init' method."

        if not obj?
            throw new Error "MongoDb.insert: no object (second argument) was specified."

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                callback err, result

        # Set collection object.
        dbCollection = @connection.collection collection

        # Execute insert!
        dbCollection.insert obj, dbCallback
        logger.debug "MongoDb.insert", collection

    ###
    # Update existing documents on the database.
    # The `options` parameter is optional.
    # @param {String} collection The collection name.
    # @param {Object} obj Document or data to be updated.
    # @param {Object} options Optional, options to control and filter the insert behaviour.
    # @param {Object} [options.filter] Defines the query filter. If not specified, will try using the ID of the passed object.
    # @param {Boolean} [options.patch] Default is false, if true replace only the specific properties of documents instead of the whole data, using $set.
    # @param {Boolean} [options.upsert] Default is false, if true it will create documents if none was found.
    # @param {Function} callback Callback (err, result) when operation has finished.
    ###
    update: (collection, obj, options, callback) ->
        if not callback? and lodash.isFunction options
            callback = options
            options = {}

        if not @connection?
            throw new Error "MongoDb.update: the db was not initialized, please check database settings and call its 'init' method."

        # Object or filter is mandatory.
        if not obj?
            throw new Error "MongoDb.update: no object (second argument) was specified."

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                callback err, result

        # Set collection object.
        dbCollection = @connection.collection collection

        # Make sure the ID is converted to ObjectID.
        if obj._id?
            id = mongoskin.ObjectID.createFromHexString obj._id.toString()

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
            logger.debug "MongoDb.update", collection, options, "ID: #{id}"
        else
            logger.debug "MongoDb.update", collection, options, "New document."

    ###
    # Delete an object from the database. The `obj` argument can be either the document itself, or its integer/string ID.
    # @param {String} collection The collection name.
    # @param {Object} filter If a string or number, assume it's the document ID. Otherwise assume the document itself.
    # @param {Function} callback Callback (err, result) when operation has finished.
    ###
    remove: (collection, filter, callback) ->
        if not callback? and lodash.isFunction options
            callback = options
            options = {}

        if not @connection?
            throw new Error "MongoDb.remove: the db was not initialized, please check database settings and call its 'init' method."

        # Filter is mandatory.
        if not filter?
            throw new Error "MongoDb.remove: no filter (second argument) was specified."

        # Check it the `obj` is the model itself, or only the ID string / number.
        if filter._id?
            id = filter._id
        else
            t = typeof filter
            id = filter if t is "string" or t is "integer"

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                callback err, result

        # Set collection object and remove specified object from the database.
        dbCollection = @connection.collection collection

        # Remove object by ID or filter.
        if id? and id isnt ""
            dbCollection.removeById id, dbCallback
        else
            dbCollection.remove filter, dbCallback

        logger.debug "MongoDb.remove", collection, filter

    ###
    # Count documents from the database. A `collection` must be specified.
    # If no `filter` is not passed then count all documents.
    # @param {String} collection The collection name.
    # @param {Object} filter Optional, keys-values filter of documents to be counted.
    # @param {Function} callback Callback (err, result) when operation has finished.
    ###
    count: (collection, filter, callback) ->
        if not callback? and lodash.isFunction filter
            callback = filter
            filter = {}

        if not @connection?
            throw new Error "MongoDb.count: the db was not initialized, please check database settings and call its 'init' method."

        # Callback is mandatory!
        if not callback?
            throw new Error "MongoDb.count: a callback (last argument) must be specified."

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                logger.debug "MongoDb.count", collection, filter, "Result #{result}"
                callback err, result

        # MongoDB has a built-in count so use it.
        dbCollection = @connection.collection collection
        dbCollection.count filter, dbCallback

# Singleton implementation
# -----------------------------------------------------------------------------
MongoDb.getInstance = ->
    @instance = new MongoDb() if not @instance?
    return @instance

module.exports = exports = MongoDb.getInstance()
