# EXPRESSER DATABASE - TINGODB
# -----------------------------------------------------------------------------
# Handles TingoDB database transactions, which is quite similar to MongoDB. This
# plugin attaches itself to the main `database` module of Expresser.
# <!--
# @see settings.database.tingodb
# -->
class DatabaseTingoDb

    priority: 3

    path = require "path"
    tingodb = require("tingodb")()
    database = null
    lodash = null
    logger = null
    settings = null
    utils = null

    # INIT
    # -------------------------------------------------------------------------

    # Init the TingoDB database module.
    # @return {Object} Returns the TingoDB transport created (only if default settings are set).
    init: =>
        database = @expresser.database
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        settings = @expresser.settings
        utils = @expresser.utils

        database.drivers.tingodb = this

        logger.debug "DatabaseTingoDb.init"
        events.emit "DatabaseTingoDb.before.init"

        # Auto register as "tingodb" if a `dbPath` is defined on the settings.
        if settings.database.tingodb.enabled and settings.database.tingodb.dbPath?
            result = database.register "tingodb", "tingodb", settings.database.tingodb.dbPath, settings.database.tingodb.options

        events.emit "DatabaseTingoDb.on.init"
        delete @init

        return result

    # Get the DB connection object.
    # @param {Object} dbPath Path to the TingoDB file to be loaded.
    # @param {Object} options Additional options to be passed when creating the TingoDB connection.
    getConnection: (dbPath, options) =>
        logger.debug "DatabaseTingoDb.getConnection", dbPath, options

        # Make sure database folder exists!
        dbPath = path.resolve dbPath
        utils.mkdirRecursive dbPath

        return {dbPath: dbPath, connection: new tingodb.Db(dbPath, options)}

    # DB IMPLEMENTATION
    # -------------------------------------------------------------------------

    # ATTENTION! All methods below are bound to the object returned by `getConnection` (above on INIT section).

    # Get data from the database. A `collection` and `callback` must be specified. The `filter` is optional.
    # Please note that if `filter` has an _id or id field, or if it's a plain string or number, it will be used
    # to return documents by ID. Otherwise it's used as keys-values object for filtering.
    # @param {String} collection The collection name.
    # @param {Object} filter Optional, if a string or number, assume it's the document ID. Otherwise assume keys-values filter.
    # @param {Object} options Options to be passed to the query.
    # @option options {Integer} limit Limits the resultset to X documents.
    # @param {Method} callback Callback (err, result) when operation has finished.
    get: (collection, filter, options, callback) ->
        if not callback?
            if lodash.isFunction options
                callback = options
                options = null
            else if lodash.isFunction filter
                callback = filter
                filter = null

        if not @connection?
            throw new Error "DatabaseTingoDb.get: the db was not initialized, please check database settings and call its 'init' method."

        # Callback is mandatory!
        if not callback?
            throw new Error "DatabaseTingoDb.get: a callback (last argument) must be specified."

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                callback err, result

        # Set collection object.
        dbCollection = @connection.collection "#{collection}.tingo"

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
            logger.debug "DatabaseTingoDb.get", collection, filterLog, options
        else
            logger.debug "DatabaseTingoDb.get", collection, "No filter.", options

    # Add new documents to the database.
    # The `options` parameter is optional.
    # @param {String} collection The collection name.
    # @param {Object} obj Document or array of documents to be added.
    # @param {Method} callback Callback (err, result) when operation has finished.
    insert: (collection, obj, callback) ->
        if not @connection?
            throw new Error "DatabaseTingoDb.insert: the db was not initialized, please check database settings and call its 'init' method."

        # Object is mandatory!
        if not obj?
            throw new Error "DatabaseTingoDb.insert: no object (second argument) was specified."

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                callback err, result

        # Set collection object.
        dbCollection = @connection.collection "#{collection}.tingo"

        # Execute insert!
        dbCollection.insert obj, dbCallback
        logger.debug "DatabaseTingoDb.insert", collection

    # Update existing documents on the database.
    # The `options` parameter is optional.
    # @param {String} collection The collection name.
    # @param {Object} obj Document or data to be updated.
    # @param {Object} options Optional, options to control and filter the insert behaviour.
    # @option options {Object} filter Defines the query filter. If not specified, will try using the ID of the passed object.
    # @option options {Boolean} patch Default is false, if true replace only the specific properties of documents instead of the whole data, using $set.
    # @option options {Boolean} upsert Default is false, if true it will create documents if none was found.
    # @param {Method} callback Callback (err, result) when operation has finished.
    update: (collection, obj, options, callback) ->
        if not callback? and lodash.isFunction options
            callback = options
            options = {}

        if not @connection?
            throw new Error "DatabaseTingoDb.update: the db was not initialized, please check database settings and call its 'init' method."

        # Object or filter is mandatory.
        if not obj?
            throw new Error "DatabaseTingoDb.update: no object (second argument) was specified."

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                callback err, result

        # Set collection object.
        dbCollection = @connection.collection "#{collection}.tingo"

        # Make sure options is valid.
        options = {} if not options?

        # If a `filter` option was set, use it as the query filter otherwise use the "_id" property.
        if options.filter?
            filter = options.filter
        else
            filter = {_id: obj._id}
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
            logger.debug "DatabaseTingoDb.update", collection, options, "ID: #{id}"
        else
            logger.debug "DatabaseTingoDb.update", collection, options, "New document."

    # Delete an object from the database. The `obj` argument can be either the document itself, or its integer/string ID.
    # @param {String} collection The collection name.
    # @param {Object} filter If a string or number, assume it's the document ID. Otherwise assume the document itself.
    # @param {Method} callback Callback (err, result) when operation has finished.
    remove: (collection, filter, callback) ->
        if not callback? and lodash.isFunction options
            callback = options
            options = {}

        if not @connection?
            throw new Error "DatabaseTingoDb.remove: the db was not initialized, please check database settings and call its 'init' method."

        # Filter is mandatory.
        if not filter?
            throw new Error "DatabaseTingoDb.remove: no filter (second argument) was specified."

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
        dbCollection = @connection.collection "#{collection}.tingo"

        # Remove object by ID or filter.
        if id? and id isnt ""
            dbCollection.removeById id, dbCallback
        else
            dbCollection.remove filter, dbCallback

        logger.debug "DatabaseTingoDb.remove", collection, filter

    # Count documents from the database. A `collection` must be specified.
    # If no `filter` is not passed then count all documents.
    # @param {String} collection The collection name.
    # @param {Object} filter Optional, keys-values filter of documents to be counted.
    # @param {Method} callback Callback (err, result) when operation has finished.
    count: (collection, filter, callback) ->
        if not callback? and lodash.isFunction filter
            callback = filter
            filter = {}

        if not @connection?
            throw new Error "DatabaseTingoDb.count: the db was not initialized, please check database settings and call its 'init' method."

        # Callback is mandatory!
        if not callback?
            throw new Error "DatabaseTingoDb.count: a callback (last argument) must be specified."

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                logger.debug "DatabaseTingoDb.count", collection, filter, "Result #{result}"
                callback err, result

        # TingoDB has a built-in count so use it.
        dbCollection = @connection.collection "#{collection}.tingo"
        dbCollection.count filter, dbCallback

# Singleton implementation.
# -----------------------------------------------------------------------------
DatabaseTingoDb.getInstance = ->
    @instance = new DatabaseTingoDb() if not @instance?
    return @instance

module.exports = exports = DatabaseTingoDb.getInstance()
