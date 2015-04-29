# EXPRESSER DATABASE
# -----------------------------------------------------------------------------
# Wrapper for databases. This module by itself won't do anything, as you'll
# need to add database driver plugins for your desired DB. At the moment we
# officially support MongoDB (plugin expresser-database-mongo).
# <!--
# @see Settings.database
# -->
class Database

    lodash = require "lodash"
    logger = require "./logger.coffee"
    settings = require "./settings.coffee"

    # @property [Object] Available database drivers.
    drivers: {}

    # @property [Object] Dictionary of database objects.
    # For simple applications this will only have one property using the
    # first available driver with a valid connection string. For example "mongo".
    db: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init the mongo database module and test the connection straight away.
    # @param [Object] options Database init options.
    init: (options) =>
        logger.debug "Database.init", options
        lodash.assign settings.database, options if options?

    # IMPLEMENTATION
    # -------------------------------------------------------------------------

    # Helper to set the current DB object. Can be called externally but ideally you should control
    # the connection string by updating your app settings.json file.
    # @param [Object] id The ID of the database to be registered. Must be unique.
    # @param [Object] driver The database driver to be used, for example mongo.
    # @param [Object] connString The connection string, for example user:password@hostname/dbname.
    # @param [Object] options Additional options to be passed when creating the DB connection object.
    register: (id, driver, connString, options) =>
        if not @drivers[driver]?
            logger.error "Database.register", "The driver #{driver} is not installed! Please check if plugin expresser-database-#{driver} is available on the current environment."
            return false
        else
            logger.info "Database.register", id, driver, options

            @db[id] = {obj: @drivers[driver].setDb connString, options}
            @db.get = -> @drivers[driver].get

    # Helper to get the first database in case there's only one registered.
    getDefaultDb: =>
        keys = lodash.keys @db
        if keys.length is 1
            return @db[keys[0]]
        else
            return null

    # Helper for single database applications, this will call the correspondent methods
    # of the "defaultdb" database, if there's one.
    get: => @getDefaultDb()?.get.call arguments
    insert: => @getDefaultDb()?.insert.call arguments
    update: => @getDefaultDb()?.update.call arguments
    remove: => @getDefaultDb()?.remove.call arguments
    count: => @getDefaultDb()?.count.call arguments

# Singleton implementation.
# -----------------------------------------------------------------------------
Database.getInstance = ->
    @instance = new Database() if not @instance?
    return @instance

module.exports = exports = Database.getInstance()
