# EXPRESSER CRON
# -----------------------------------------------------------------------------
# Handle scheduled / cron jobs.

class Cron

    lodash = require "lodash"
    logger = require "./logger.coffee"
    settings = require "./settings.coffee"

    # Jobs array object.
    jobs: {}


    # INIT
    # -------------------------------------------------------------------------

    # Init the databse by testing the connection.
    init: =>
        logger.debug "Expresser", "Cron.init"


    # METHODS
    # -------------------------------------------------------------------------

    # Start the cron jobs.
    start: =>
        clearInterval job.timer for job of @jobs
        @jobs = {}

    # Add a scheduled job to the cron.
    add: (id, options) =>
        if @jobs[id]?
            if settings.cron.allowReplacing
                clearInterval @jobs[id].timer
            else
                logger.error "Expresser", "Cron.add", "Job #{id} already exists and 'allowReplacing' is false. Abort!"
                return

        job = {}
        job.timer = getTimer options

        # Add to the jobs list.
        @jobs[id] = job

    # Remove and stop a current job. If job does not exist, a warning will be logged.
    remove: (id) =>
        if not @jobs[id]?
            logger.warn "Expresser", "Cron.remove", "Job #{id} does not exist. Abort!"
            return

        clearInterval @jobs[id]
        delete @jobs[id]


    # HELPERS
    # -------------------------------------------------------------------------

    # Helper to get a timer / interval based on the defined options.
    getTimer = (options) ->
        schedule = options.schedule
        return setInterval options.callback, schedule


# Singleton implementation.
# -----------------------------------------------------------------------------
Cron.getInstance = ->
    @instance = new Cron() if not @instance?
    return @instance

module.exports = exports = Cron.getInstance()