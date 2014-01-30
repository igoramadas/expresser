# EXPRESSER DATABASE
# -----------------------------------------------------------------------------
# Handles MongoDB database transactions using the `mongoskin` module. It supports
# a very simple failover mechanism where you can specify a "backup" connection
# string to which the module will connect in case the main database is down.
# <!--
# @see Settings.database
# -->
class Database

    lodash = require "lodash"
    logger = require "./logger.coffee"
    settings = require "./settings.coffee"
    mongo = require "mongoskin"

    # @property [Object] Database object (using mongoskin), will be set during `init`.
    db: null

    # @property [Boolean] When using the failover/secondary databse this will be set to true.
    failover: false

    # @property [Method] Callback (result) triggered when a connection is validated sucessfully.
    onConnectionValidated: null

    # @property [Method] Callback (err) triggered when a connection fails.
    onConnectionError: null

    # @property [Method] Callback (isFailover) triggered when a connection switches to (true) or from (false) failover.
    onFailoverSwitch: null

    # INIT
    # -------------------------------------------------------------------------

    # Init the databse module and test the connection straight away.
    # @param [Object] options Database init options.
    init: (options) =>
        if settings.database.connString? and settings.database.connString isnt ""
            @validateConnection()
        else if settings.database.connString2? and settings.database.connString2 isnt ""
            @validateConnection()
            logger.warn "Database.init", "The connString is empty but connString2 is set.", "Please set connString first (module will still work)."
        else
            logger.debug "Database.init", "No connection string set.", "Database module won't work."

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
    get: (collection, filter, options, callback) =>
        if not callback?
            if lodash.isFunction options
                callback = options
                options = null
            else if lodash.isFunction filter
                callback = filter
                filter = null

        # Callback is mandatory!
        if not callback?
            if settings.logger.autoLogErrors
                logger.error "Database.get", "No callback specified. Abort!", collection, filter
            throw new Error "Database.get: a callback (last argument) must be specified."

        # No DB set? Throw exception.
        if not @db?
            if settings.logger.autoLogErrors
                logger.error "Database.get", "The db is null or was not initialized. Abort!", collection, filter
            return callback "Database.set: the db was not initialized, please check database settings and call its 'init' method."

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                result = @normalizeId result if settings.database.normalizeId
                callback err, result

        # Set collection object.
        dbCollection = @db.collection collection

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
                dbCollection.find().limit(limit).toArray dbCallback
            else
                dbCollection.find().toArray dbCallback

        if filter?
            filterLog = filter
            filterLog.password = "***" if filterLog.password?
            filterLog.passwordHash = "***" if filterLog.passwordHash?
            logger.debug "Database.get", collection, filterLog, options
        else
            logger.debug "Database.get", collection, "No filter.", options

    # Insert or update documents on the database using Mongo's upsert command.
    # The `options` parameter is optional.
    # @param [String] collection The collection name.
    # @param [Object] obj Document or data to be added / updated.
    # @param [Object] options Optional, options to control and filter the upsert behaviour.
    # @option options [Object] filter Defines the query filter. If not specified, will try using the ID of the passed object.
    # @option options [Boolean] patch Default is false, if true replace only the specific properties of documents instead of the whole data, using $set.
    # @option options [Boolean] upsert Default is true, if false it won't add a new document (only update existing).
    # @param [Method] callback Callback (err, result) when operation has finished.
    set: (collection, obj, options, callback) =>
        if not callback? and lodash.isFunction options
            callback = options
            options = {}

        # Object or filter is mandatory.
        if not obj?
            if settings.logger.autoLogErrors
                logger.error "Database.set", "No object specified. Abort!", collection
            if callback?
                callback "Database.set: no object (second argument) was specified."
            return false

        # No DB set? Throw exception.
        if not @db?
            if settings.logger.autoLogErrors
                logger.error "Database.set", "The db is null or was not initialized. Abort!", collection
            if callback?
                callback "Database.set: the db was not initialized, please check database settings and call its 'init' method."
            return false

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                result = @normalizeId(result) if settings.database.normalizeId
                callback err, result

        # Set collection object.
        dbCollection = @db.collection collection

        # Make sure the ID is converted to ObjectID.
        if obj._id?
            id = mongo.ObjectID.createFromHexString obj._id.toString()
        else if obj.id? and settings.database.normalizeId
            id = mongo.ObjectID.createFromHexString obj.id.toString()

        # If a `filter` option was set, use it as the query filter otherwise use the "_id" property.
        if options.filter?
            filter = options.filter
        else
            filter = {"_id": id}

        # If a `sort` option was set, use it as sorting otherwise use the default "_id" property.
        if options.sort?
            sort = {"sort": options.sort}
        else if id?
            sort = {"sort": "_id"}
        else
            sort = null

        # If options patch is set, replace specified document properties only instead of replacing the whole document.
        if options.patch
            docData = {$set: obj}
        else
            docData = obj

        # Check upsert option, if false it won't add new documents.
        if options.upsert?
            upsert = options.upsert
        else
            upsert = true

        # Execute updated!
        dbCollection.findAndModify filter, sort, docData, {"new": true, "upsert": upsert}, dbCallback

        if id?
            logger.debug "Database.set", collection, options, "ID: #{id}"
        else
            logger.debug "Database.set", collection, options, "New document."


    # Delete an object from the database. The `obj` argument can be either the document itself, or its integer/string ID.
    # This can also be called as `delete`.
    # @param [String] collection The collection name.
    # @param [String, Object] filter If a string or number, assume it's the document ID. Otherwise assume the document itself.
    # @param [Method] callback Callback (err, result) when operation has finished.
    del: (collection, filter, callback) =>
        if not callback? and lodash.isFunction options
            callback = options
            options = {}

        # Filter is mandatory.
        if not filter?
            if settings.logger.autoLogErrors
                logger.error "Database.del", "No filter specified. Abort!", collection
            if callback?
                callback "Database.del: no filter (second argument) was specified."
            return false

        # No DB set? Throw exception.
        if not @db?
            if settings.logger.autoLogErrors
                logger.error "Database.del", "The db is null or was not initialized. Abort!", collection
            if callback?
                callback "Database.del: the db was not initialized, please check database settings and call its 'init' method."
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
                result = @normalizeId(result) if settings.database.normalizeId
                callback err, result

        # Set collection object and remove specified object from the database.
        dbCollection = @db.collection collection

        # Remove object by ID or filter.
        if id? and id isnt ""
            dbCollection.removeById id, dbCallback
        else
            dbCollection.remove filter, dbCallback

        logger.debug "Database.del", collection, filter

    # Alias to `del`.
    delete: (collection, filter, callback) =>
        @del collection, filter, callback

    # Count documents from the database. A `collection` must be specified.
    # If no `filter` is not passed then count all documents.
    # @param [String] collection The collection name.
    # @param [Object] filter Optional, keys-values filter of documents to be counted.
    # @param [Method] callback Callback (err, result) when operation has finished.
    count: (collection, filter, callback) =>
        if not callback? and lodash.isFunction filter
            callback = filter
            filter = {}

        # Callback is mandatory!
        if not callback?
            if settings.logger.autoLogErrors
                logger.error "Database.count", "No callback specified. Abort!", collection, filter
            throw new Error "Database.count: a callback (last argument) must be specified."

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                logger.debug "Database.count", collection, filter, "Result #{result}"
                callback err, result

        # MongoDB has a built-in count so use it.
        dbCollection = @db.collection collection
        dbCollection.count filter, dbCallback

    # HELPER METHODS
    # -------------------------------------------------------------------------

    # Helper to transform MongoDB document "_id" to "id".
    # @param [Object] result The document or result to be normalized.
    # @return [Object] Returns the normalized document.
    normalizeId: (result) =>
        return if not result?

        isArray = lodash.isArray result or lodash.isArguments result

        # Check if result is a collection / array or a single document.
        if isArray
            for obj in result
                obj["id"] = obj["_id"].toString()
                delete obj["_id"]
        else
            result["id"] = result["_id"].toString()
            delete result["_id"]

        return result

    # Helper method to check the DB connection. If connection fails multiple times in a row,
    # switch to the failover DB (specified on the `Database.connString2` setting).
    # @param [Integer] retry Optional, current retry number, default is 0.
    # @private
    validateConnection: (retry) =>
        retry = 0 if not retry?

        # If connection has failed repeatedly for more than 2 times the `maxRetries` value
        # then stop trying and log an error.
        if retry > settings.database.maxRetries * 2
            logger.critical
            return logger.error "Database.validateConnection", "Connection failed #{retry} times, abort!", @getDbInfo()

        # First try using main database. If `failover` is true this will trigger the `onFailoverSwitch` event.
        if retry < 1
            @setDb settings.database.connString, settings.database.options
            @onFailoverSwitch? false if @failover
            @failover = false
            logger.debug "Database.validateConnection", "Using main DB.", @getDbInfo()

        # Reached max retries? Try connecting to the failover database, if there's one specified.
        if retry is settings.database.maxRetries
            if settings.database.connString2? and settings.database.connString2 isnt ""
                @setDb settings.database.connString2, settings.database.options
                @onFailoverSwitch? true if not @failover
                @failover = true
                logger.info "Database.validateConnection", "Connection failed #{retry} times.", "Switching to failover DB.", @getDbInfo()
            else
                logger.error "Database.validateConnection", "Connection failed #{retry} times.", "No failover DB set, keep trying."

        # Try to connect to the current database. If it fails, try again in a few seconds.
        @db.open (err, result) =>
            if err?
                logger.debug "Database.validateConnection", "Failed to connect.", "Retry #{retry}.", @getDbInfo()
                setTimeout (() => @validateConnection retry + 1), settings.database.retryInterval

                # Trigger connection error.
                @onConnectionError? err

            else

                # If using the failover database, register a timeout to try
                # to connect to the main database again.
                if @failover
                    timeout = settings.database.failoverTimeout
                    setTimeout @validateConnection, timeout * 1000
                    logger.debug "Database.validateConnection", "Connected to failover DB.", "Will try main DB again in #{timeout} seconds."
                else
                    logger.debug "Database.validateConnection", "Connected to main DB."

                # Trigger connection validated.
                @onConnectionValidated? result

    # Helper to set the current DB object. Can be called externally but ideally you should control
    # the connection string by updating your app settings.json file.
    # Calling this directly won't change the `failover` flag!
    # @param [Object] connString The connection string, for example user:password@hostname/dbname.
    # @param [Object] options Additional options to be passed when creating the DB connection object.
    setDb: (connString, options) =>
        @db = mongo.db connString, options

        # Safe logging, strip username and password.
        sep = connString.indexOf "@"
        connStringSafe = connString
        connStringSafe = connStringSafe.substring sep if sep > 0
        logger.debug "Database.setDb", connStringSafe, options

    # Helper to get connection (host, port, db name) info about the current database / mongo object.
    # @return [String] Single line string with db information.
    # @private
    getDbInfo: =>
        if not @db?
            return logger.debug "Database.getDbInfo", "Invalid DB (null or undefined)."
        return "#{@db._dbconn.serverConfig.name}/#{@db._dbconn.databaseName}"


# Singleton implementation.
# -----------------------------------------------------------------------------
Database.getInstance = ->
    @instance = new Database() if not @instance?
    return @instance

module.exports = exports = Database.getInstance()