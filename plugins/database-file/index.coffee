# EXPRESSER DATABASE - FILE
# -----------------------------------------------------------------------------
# Simple implementation of databases stored as JSON files on the file system.
# Each collection is represented by a single JSON file.
# The plugin attaches itself to the main `database` module of Expresser.
# <!--
# @see settings.database.file
# -->
class DatabaseFile

    fs = require "fs"
    database = null
    lodash = null
    logger = null
    settings = null
    utils = null

    # INIT
    # -------------------------------------------------------------------------

    # Init the File database module.
    # @param [Object] options Database init options.
    init: (options) =>
        database = @expresser.database
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        settings = @expresser.settings
        utils = @expresser.utils

        database.drivers.file = this

        logger.debug "DatabaseFile.init", options

        options = {} if not options?
        options = lodash.defaultsDeep options, settings.database.file

        if options.enabled and options.path?
            return database.register "file", "file", options.path, options.options

    # Get the DB connection object.
    # @param [Object] dbPath Path where database files should be stored.
    # @param [Object] options Additional options to be passed when creating the DB connection object.
    getConnection: (dbPath, options) =>
        sep = connString.indexOf "@"
        connStringSafe = connString
        connStringSafe = connStringSafe.substring sep if sep > 0
        logger.debug "DatabaseFile.getConnection", connStringSafe, options

        # DB path must end with a slash.
        dbPath += "/" if dbPath.substr(dbPath.length - 1) isnt "/"

        return {dbPath: dbPath}

    # FILE OPERATIONS
    # -------------------------------------------------------------------------

    # Helper to read and get the contents of a collection.
    # @param [String] collection The collection (file name) to be read.
    # @param [Method] callback Callback (err, result) with collection data.
    # @private
    readFromDisk: (collection, callback) ->
        filepath = utils.getFilePath @dbPath + collection + ".json"

        # Check if file exists before proceeding.
        fs.exists filepath, (exists) ->
            if not exists
                return callback null, null
            else

                # Try reading and parsing the collection (file) as JSON.
                fs.readFileSync filename, {encoding: settings.general.encoding}, (err, data) ->
                    if err?
                        logger.autoLogError "DatabaseFile.readFromDisk", filepath, err
                        return callback {message: "Could not read #{filepath}", error: err}

                    try
                        data = JSON.parse data
                    catch ex
                        logger.autoLogError "DatabaseFile.readFromDisk", filepath, ex
                        return callback {message: "Could not parse #{filepath}", error: ex}

    # Save data to disk.
    writeToDisk: (collection, data, callback) ->
        filepath = utils.getFilePath @dbPath + collection + ".json"

        fs.writeFile filepath, data, {encoding: settings.general.encoding}, (err, result) ->
            if err?
                logger.autoLogError "DatabaseFile.writeToDisk", filepath, err
                return callback {message: "Could not write to #{filepath}", error: err}

            callback null, true

    # CRUD IMPLEMENTATION
    # -------------------------------------------------------------------------

    # Get data from the database. A `collection` and `callback` must be specified. The `filter` is optional.
    # The underlying filtering is done with lodash `filter` method.
    # @param [String] collection The collection (filename, without .json).
    # @param [String, Object] filter Optional, can be an object, string, number or function.
    # @param [Method] callback Callback (err, result) when operation has finished.
    get: (collection, filter, callback) ->
        logger.debug "DatabaseFile.get", collection, filter

        if not callback? and lodash.isFunction filter
            callback = filter
            filter = null

        # Callback is mandatory!
        if not callback?
            err = new Error "DatabaseFile.get: a callback (last argument) must be specified."
            logger.autoLogError "DatabaseFile.get", collection, err
            throw err

        # Get collection data from disk.
        @readFromDisk collection, (err, data) ->
            if err?
                return callback {message: "Could not read data from #{collection}.", error: err}

            # Return null if no data was found.
            if not data?
                return callback null, null

            result = lodash.filter data, filter
            callback null, result

    # Add new document(s) to the JSON file. The `collection` and `obj` are mandatory.
    # @param [String] collection The collection (filename, without .json).
    # @param [Object] obj Document or array of documents to be added.
    # @param [Method] callback Callback (err, result) when operation has finished. Result is added object.
    insert: (collection, obj, callback) ->
        logger.debug "DatabaseFile.insert", collection, obj

        if not obj?
            err = new Error "DatabaseFile.insert: an object (second argument) must be passed."
            logger.autoLogError "DatabaseFile.insert", collection, err
            throw err

        # Get collection data from disk.
        @readFromDisk collection, (err, data) ->
            if err?
                return callback {message: "Could not read data from #{collection}.", error: err}

            # No data yet? Initiate the collection with a new array.
            if not data?
                data = [obj]

            # Save changes to disk!
            @writeToDisk collection, data, (err, ok) ->
                if err?
                    return callback {message: "Could not write to #{collection}.", error: err}

                return callback null, obj

    # Update existing data on the JSON file. The `collection` and `obj` are mandatory.
    # Values are merged with the
    # @param [String] collection The collection (filename, without .json).
    # @param [Object] obj Document or data to be updated.
    # @param [Object] options Options to filter and define how data is updated.
    # @option options [Object] filter Filter data to be updated (using lodash filter).
    # @option options [Object] merge Merge data by default, if false data will be overwritten.
    # @param [Method] callback Callback (err, result) when operation has finished. Result is array of changed items.
    update: (collection, obj, options, callback) ->
        logger.debug "DatabaseFile.update", collection, obj, options

        if not callback? and lodash.isFunction options
            callback = options
            options = {}

        options.merge = true if not options.merge?

        # Object or filter is mandatory.
        if not obj?
            err = new Error "DatabaseFile.update: an object (second argument) must be passed."
            logger.autoLogError "DatabaseFile.update", collection, err
            throw err

        # Get collection data from disk.
        @readFromDisk collection, (err, data) ->
            if err?
                return callback {message: "Could not read data from #{collection}.", error: err}

            # No data yet? Initiate the collection with a new array.
            if not data?
                filtered = [obj]
            else
                if options.filter?
                    filtered = lodash.filter data, options.filter

            # Merge or replace data depending on `options.merge`.
            for i in filtered
                delete i[key] for key, value of i if not options.merge
                lodash.assignIn i, obj

            # Save changes to disk!
            @writeToDisk collection, data, (err, ok) ->
                if err?
                    return callback {message: "Could not write to #{collection}.", error: err}

                return callback null, filtered

    # Delete an object from the JSON file. The `obj` argument is mandatory.
    # This uses the lodash `remove` helper.
    # @param [String] collection The collection (filename, without .json).
    # @param [String, Object] filter If a string or number, assume it's the document ID. Otherwise assume the document itself.
    # @param [Method] callback Callback (err, result) when operation has finished. Result is the array of removed items.
    remove: (collection, filter, callback) ->
        logger.debug "DatabaseFile.remove", collection, filter

        if not callback? and lodash.isFunction options
            callback = options
            options = {}

        # Filter is mandatory.
        if not filter?
            err = new Error "DatabaseFile.remove: a filter (second argument) must be passed."
            logger.autoLogError "DatabaseFile.remove", collection, err
            throw err

        # Get collection data from disk.
        @readFromDisk collection, (err, data) ->
            if err?
                return callback {message: "Could not read data from #{collection}.", error: err}

            # Remove from data original.
            removed = lodash.remove data, filter

            # Save changes to disk!
            @writeToDisk collection, data, (err, ok) ->
                if err?
                    return callback {message: "Could not write to #{collection}.", error: err}

                return callback null, removed

# Singleton implementation.
# -----------------------------------------------------------------------------
DatabaseFile.getInstance = ->
    @instance = new DatabaseFile() if not @instance?
    return @instance

module.exports = exports = DatabaseFile.getInstance()
