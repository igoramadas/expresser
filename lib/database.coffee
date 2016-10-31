# EXPRESSER DATABASE
# -----------------------------------------------------------------------------
# Wrapper for databases. This module by itself won't do anything, as you'll
# need to add database driver plugins for your desired DB. At the moment we
# officially support MongoDB (plugin expresser-database-mongo).
# <!--
# @see settings.database
# -->
class Database
    newInstance: -> return new Database()

    events = require "./events.coffee"
    lodash = require "lodash"
    logger = require "./logger.coffee"
    settings = require "./settings.coffee"

    # PUBLIC PROPERTIES
    # --------------------------------------------------------------------------

    # @property {Object} Available database drivers.
    drivers: {}

    # @property {Object} Dictionary of database objects.
    db: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init the database module.
    # @param {Object} options Database init options.
    init: (options) =>
        logger.debug "Database.init", options
        lodash.assign settings.database, options if options?

        @setEvents() if settings.events.enabled

    # Bind events.
    setEvents: =>
        events.on "Database.register", @register

    # IMPLEMENTATION
    # -------------------------------------------------------------------------

    # Helper to register database objects.
    # @param {Object} id The ID of the database to be registered. Must be unique.
    # @param {Object} driver The database driver to be used, for example mongo.
    # @param {Object} connString The connection string, for example user:password@hostname/dbname.
    # @param {Object} options Additional options to be passed when creating the DB connection object.
    register: (id, driver, connString, options) =>
        if not @drivers[driver]?
            logger.error "Database.register", "The driver #{driver} is not installed! Please check if plugin expresser-database-#{driver} is available on the current environment."
            return false
        else
            logger.debug "Database.register", id, driver, options

            @db[id] = @drivers[driver].getConnection connString, options
            @db[id].get = @drivers[driver].get
            @db[id].insert = @drivers[driver].insert
            @db[id].update = @drivers[driver].update
            @db[id].remove = @drivers[driver].remove
            @db[id].count = @drivers[driver].count

            return @db[id]

# Singleton implementation.
# -----------------------------------------------------------------------------
Database.getInstance = ->
    @instance = new Database() if not @instance?
    return @instance

module.exports = exports = Database.getInstance()