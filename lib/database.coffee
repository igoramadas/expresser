# EXPRESSER DATABASE
# -----------------------------------------------------------------------------
# Handle the MongoDB database interactions on the app.
# Parameters on settings.coffee: Settings.Database

class Database

    logger = require "./logger.coffee"
    settings = require "./settings.coffee"
    mongo = require "mongoskin"

    # Database object, will be set during `init`.
    db = null

    # When using the failover/secondary databse, `failover` will be set to true.
    failover: false


    # INTERNAL FEATURES
    # -------------------------------------------------------------------------

    # Helper method to check the DB connection. If connection fails multiple times in a row,
    # switch to the failover DB (specified on the `Database.connString2` setting).
    # You can customize these values on the `Database` [settings](settings.html).
    validateConnection = (retry) ->
        retry = 0 if not retry?

        # If connection has failed repeatedly for more than 3 times the `maxRetries` value then
        # stop trying and log an error.
        if retry > settings.Database.maxRetries * 3
            logger.error "Expresser", "Database.validateConnection", "Connection failed #{retry} times.", "Abort!"
            return

        # First try, use main database.
        if retry < 1
            db = mongo.db settings.Database.connString, settings.Database.options
            @failover = false

        # Reached max retries? Try connecting to the failover database, if there's one specified.
        if retry is settings.Database.maxRetries
            if settings.Database.connString2? and settings.Database.connString2 isnt ""
                @failover = true
                db = mongo.db settings.Database.connString2, settings.Database.options
                logger.info "Expresser", "Database.validateConnection", "Connection failed #{retry} times.", "Switched to failover database."
            else
                logger.error "Expresser", "Database.validateConnection", "Connection failed #{retry} times.", "No failover database set, keep trying."

        # Try to connect to the current database. If it fails, try again in a few seconds.
        db.open (err, result) =>
            if err?
                if settings.General.debug
                    logger.warn "Expresser", "Database.validateConnection", "Failed to connect.", "Retry #{retry}."
                setTimeout (() -> validateConnection retry + 1), settings.Database.retryInterval
            else if settings.General.debug
                # If using the failover database, register a timeout to try
                # to connect to the main database again.
                if @failover
                    setTimeout validateConnection, settings.Database.failoverTimeout * 1000
                    logger.info "Expresser", "Database.validateConnection", "Connected to failover database.", "Try the main again in #{settings.Database.failoverTimeout} settings."
                else
                    logger.info "Expresser", "Database.validateConnection", "Connected to main database."


    # INIT
    # -------------------------------------------------------------------------

    # Init the databse by testing the connection.
    init: =>
        if settings.Database.connString? and settings.Database.connString isnt ""
            validateConnection()
        else if settings.General.debug
            logger.warn "Expresser", "Database.init", "No connection string set.", "Database module won't work."

    # LOW LEVEL IMPLEMENTATION
    # -------------------------------------------------------------------------

    # Get data from the database. A `collection` must be specified.
    # The `options` and `callback` are optional.
    get: (collection, options, callback) =>
        if not callback?
            logger.warn "Expresser", "Database.get", "No callback specified. Abort!", collection, options
            return

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                result = @normalizeId(result) if settings.Database.normalizeId
                callback err, result

        # Set collection object.
        dbCollection = db.collection collection

        # Find documents depending on the options.
        if options?
            if options.id?
                dbCollection.findById options.id, dbCallback
            else
                dbCollection.find(options).toArray dbCallback
        else
            dbCollection.find().toArray dbCallback

        # Log if debug is true.
        if settings.General.debug
            logger.info "Expresser", "Database.get", collection, options

    # Insert or update an object on the database.
    set: (collection, obj, callback) =>
        if not obj?
            msg = "The obj argument is null or empty."
            callback msg, null
            logger.warn "Expresser", "Database.set", msg
            return

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                result = @normalizeId(result) if settings.Database.normalizeId
                callback err, result

        # Set collection object.
        dbCollection = db.collection collection

        # If object already has an ID, update it otherwise insert a new one.
        if obj.id?
            dbCollection.updateById obj.id, {$set: obj.attributes}, dbCallback
            if settings.General.debug
                logger.info "Expresser", "Database.set", "Update", collection, obj.id, obj.attributes
        else
            dbCollection.insert obj.attributes, {"new": true}, dbCallback
            if settings.General.debug
                logger.info "Expresser", "Database.set", "Insert", collection, obj.attributes


    # Delete an object from the database. The `obj` argument can be either the object
    # itself, or its integer/string ID.
    del: (collection, obj, callback) =>
        if not obj?
            msg = "The obj argument is null or empty."
            callback msg, null
            logger.warn "Expresser", "Database.del", msg
            return

        # Check it the `obj` is the model itself, or only the ID string / number.
        if obj.id?
            id = obj.id
        else
            id = obj

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                result = @normalizeId(result) if settings.Database.normalizeId
                callback err, result

        # Set collection object and remove specified document from the database.
        dbCollection = db.collection collection
        dbCollection.removeById id, dbCallback

        # Log if debug is true.
        if settings.General.debug
            logger.warn "Expresser", "Database.del", collection, obj.id, obj.attributes

    # Count data from the database. A `collection` must be specified.
    # If no `options` is passed (null or undefined) then count all documents.
    # The callback is mandatory.
    count: (collection, options, callback) =>
        if not callback?
            logger.warn "Expresser", "Database.count", "No callback specified. Abort!", collection, options
            return

        # Create the DB callback helper.
        dbCallback = (err, result) =>
            if callback?
                callback err, result
                if settings.General.debug
                    logger.info "Expresser", "Database.count", collection, options, result

        # MongoDB has a built-in count, so use it.
        dbCollection = db.collection collection
        dbCollection.count options, dbCallback


    # HELPER METHODS
    # -------------------------------------------------------------------------

    # Helper to transform MongoDB document "_id" to "id".
    normalizeId: (result) =>
        return if not result?
            
        if result.length?
            for obj in result
                obj["id"] = obj["_id"].toString()
                delete obj["_id"]
        else
            result["id"] = result["_id"].toString()
            delete result["_id"]

        return result


# Singleton implementation.
# -----------------------------------------------------------------------------
Database.getInstance = ->
    @instance = new Database() if not @instance?
    return @instance

module.exports = exports = Database.getInstance()