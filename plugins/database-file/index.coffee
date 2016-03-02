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
    path = require "path"
    database = null
    lodash = null
    logger = null
    moment = null
    settings = null
    utils = null

    # INIT
    # -------------------------------------------------------------------------

    # Init the File database module.
    # @param {Object} options Database init options.
    init: (options) =>
        database = @expresser.database
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        moment = @expresser.libs.moment
        settings = @expresser.settings
        utils = @expresser.utils

        database.drivers.file = this

        logger.debug "DatabaseFile.init", options

        options = {} if not options?
        options = lodash.defaultsDeep options, settings.database.file

        # Auto register as "file" if a default path is specified on the settings.
        if options.enabled and options.path?
            return database.register "file", "file", options.path, options.options

    # Get the DB connection object.
    # @param {Object} dbPath Path where database files should be stored.
    # @param {Object} options Additional options to be passed when creating the DB connection object.
    getConnection: (dbPath, options) =>
        logger.debug "DatabaseFile.getConnection", dbPath, options

        # DB path must end with a slash.
        dbPath += "/" if dbPath.substr(dbPath.length - 1) isnt "/"

        return {dbPath: dbPath, cache: {}, readFromDisk: @readFromDisk, writeToDisk: @writeToDisk}

    # FILE OPERATIONS
    # -------------------------------------------------------------------------

    # Helper to read and get the contents of a database file.
    # @param {String} collection The collection (file name) to be read.
    # @param {Method} callback Callback (err, result) with collection data.
    # @private
    readFromDisk: (collection, callback) ->
        filepath = @dbPath + collection + ".json"
        logger.debug "DatabaseFile.readFromDisk", filepath

        # Check if file is already open and on cache.
        if @cache[collection]?
            return callback null, @cache[collection]

        # Check if file exists before proceeding.
        fs.exists filepath, (exists) =>
            if not exists
                return callback null, null
            else

                # Try reading and parsing the collection (file) as JSON.
                fs.readFile filepath, {encoding: settings.general.encoding}, (err, data) =>
                    if err?
                        logger.error "DatabaseFile.readFromDisk", filepath, err
                        return callback {message: "Could not read #{filepath}", error: err}

                    # Set data to null if file is empty.
                    data = null if data is ""

                    # File has data? Try to parse it as JSON.
                    if data?
                        try
                            data = JSON.parse data
                        catch ex
                            logger.error "DatabaseFile.readFromDisk", filepath, ex
                            return callback {message: "Could not parse #{filepath}", error: ex}

                        # Add data to in-memory cache and st its deletion timeout.
                        @cache[collection] = data
                        deleteTimeout = -> delete @cache[collection]
                        setTimeout deleteTimeout, settings.database.file.cacheExpires * 1000

                    callback null, data

    # Helper to write data to a database file.
    # @param {String} collection The collection (file name) to be read.
    # @param {Object} data JSON data to be written on the file.
    # @param {Method} callback Callback (err, result) with collection data.
    # @private
    writeToDisk: (collection, data, callback) ->
        filepath = @dbPath + collection + ".json"
        logger.debug "DatabaseFile.writeToDisk", filepath, data

        # Make sure database directory exists.
        dirname = path.dirname filepath
        fs.exists dirname, (exists) =>
            fs.mkdirSync dirname if not exists

            # Stringify the data to be written.
            if not lodash.isString data
                data = JSON.stringify data, null, 1

            # Try writing the data to the disk.
            fs.writeFile filepath, data, {encoding: settings.general.encoding}, (err) =>
                if err?
                    logger.error "DatabaseFile.writeToDisk", filepath, err
                    return callback {message: "Could not write to #{filepath}", error: err}

                # Update cache.
                @cache[collection] = data if @cache[collection]?

                callback null, data

    # CRUD IMPLEMENTATION
    # -------------------------------------------------------------------------

    # Get data from the database. A `collection` and `callback` must be specified. The `filter` is optional.
    # The underlying filtering is done with lodash `filter` method.
    # @param {String} collection The collection (filename, without .json).
    # @param {Object} filter Optional, can be an object, string, number or function.
    # @param {Method} callback Callback (err, result) when operation has finished.
    get: (collection, filter, callback) ->
        logger.debug "DatabaseFile.get", collection, filter

        if not callback? and lodash.isFunction filter
            callback = filter
            filter = null

        # Callback is mandatory!
        if not callback?
            err = new Error "DatabaseFile.get: a callback (last argument) must be specified."
            logger.error "DatabaseFile.get", collection, err
            throw err

        # Get collection data from disk.
        @readFromDisk collection, (err, data) =>
            if err?
                return callback {message: "Could not read data from #{collection}.", error: err}

            # Return null if no data was found.
            if not data?
                return callback null, null

            result = lodash.filter data, filter
            callback null, result

    # Add new document(s) to the JSON file. The `collection` and `obj` are mandatory.
    # @param {String} collection The collection (filename, without .json).
    # @param {Object} obj Document or array of documents to be added.
    # @param {Method} callback Callback (err, result) when operation has finished. Result is added object.
    insert: (collection, obj, callback) ->
        logger.debug "DatabaseFile.insert", collection, obj

        if not obj?
            err = new Error "DatabaseFile.insert: an object (second argument) must be passed."
            logger.error "DatabaseFile.insert", collection, err
            throw err

        # Get collection data from disk.
        @readFromDisk collection, (err, data) =>
            if err?
                return callback {message: "Could not read data from #{collection}.", error: err}

            # No data yet? Initiate the collection with a new array.
            if not data?
                if lodash.isArray obj
                    data = obj
                else
                    data = [obj]
            else
                data.push obj

            # Save changes to disk!
            @writeToDisk collection, data, (err) =>
                if err?
                    return callback {message: "Could not write to #{collection}.", error: err}

                callback null, obj

    # Update existing data on the JSON file. The `collection` and `obj` are mandatory.
    # Values are merged with the
    # @param {String} collection The collection (filename, without .json).
    # @param {Object} obj Document or data to be updated.
    # @param {Object} options Options to filter and define how data is updated.
    # @option options {Object} filter Filter data to be updated (using lodash filter).
    # @option options {Object} merge Merge data by default, if false data will be overwritten.
    # @param {Method} callback Callback (err, result) when operation has finished. Result is array of changed items.
    update: (collection, obj, options, callback) ->
        logger.debug "DatabaseFile.update", collection, obj, options

        if not callback? and lodash.isFunction options
            callback = options
            options = {}

        options.merge = true if not options.merge?

        # Object or filter is mandatory.
        if not obj?
            err = new Error "DatabaseFile.update: an object (second argument) must be passed."
            logger.error "DatabaseFile.update", collection, err
            throw err

        # Get collection data from disk.
        @readFromDisk collection, (err, data) =>
            if err?
                return callback {message: "Could not read data from #{collection}.", error: err}

            # No data yet? Initiate the collection with a new array.
            if not data?
                if lodash.isArray obj
                    filtered = obj
                else
                    filtered = [obj]
            else
                if options.filter?
                    filtered = lodash.filter data, options.filter

            # Merge or replace data depending on `options.merge`.
            for i in filtered
                delete i[key] for key, value of i if not options.merge
                lodash.assignIn i, obj

            # Save changes to disk!
            @writeToDisk collection, data, (err, ok) =>
                if err?
                    return callback {message: "Could not write to #{collection}.", error: err}

                callback null, filtered

    # Delete an object from the JSON file. The `obj` argument is mandatory.
    # This uses the lodash `remove` helper.
    # @param {String} collection The collection (filename, without .json).
    # @param {Object} filter If a string or number, assume it's the document ID. Otherwise assume the document itself.
    # @param {Method} callback Callback (err, result) when operation has finished. Result is the array of removed items.
    remove: (collection, filter, callback) ->
        logger.debug "DatabaseFile.remove", collection, filter

        if not callback? and lodash.isFunction options
            callback = options
            options = {}

        # Filter is mandatory.
        if not filter?
            err = new Error "DatabaseFile.remove: a filter (second argument) must be passed."
            logger.error "DatabaseFile.remove", collection, err
            throw err

        # Get collection data from disk.
        @readFromDisk collection, (err, data) =>
            if err?
                return callback {message: "Could not read data from #{collection}.", error: err}

            # Remove from data original.
            removed = lodash.remove data, filter

            # Nothing to remove? Call back with null.
            if not removed?
                callback null, null

            @writeToDisk collection, data, (err, ok) =>
                if err?
                    return callback {message: "Could not write to #{collection}.", error: err}

                callback null, removed

# Singleton implementation.
# -----------------------------------------------------------------------------
DatabaseFile.getInstance = ->
    return new DatabaseFile() if process.env is "test"
    @instance = new DatabaseFile() if not @instance?
    return @instance

module.exports = exports = DatabaseFile.getInstance()
