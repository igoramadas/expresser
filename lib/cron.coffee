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

    # Start the specified cron job. If no `id` is specified, all jobs will be started.
    start: (id) =>
        if id? and id isnt false and id isnt ""
            logger.debug "Expresser", "Cron.start", id
            if @jobs[id]?
                clearTimeout @jobs[id].timer if @jobs[id].timer?
                setTimer @jobs[id]
        else
            logger.debug "Expresser", "Cron.start"

            clearTimeout job.timer for job of @jobs
            @jobs = {}

    # Stop the specified cron job. If no `id` is specified, all jobs will be stopped.
    stop: (id) =>
        if id? and id isnt false and id isnt ""
            logger.debug "Expresser", "Cron.stop", id
            if @jobs[id]?
                clearTimeout @jobs[id].timer
                delete @jobs[id].timer
        else
            logger.debug "Expresser", "Cron.stop"
            for job of @jobs
                clearTimeout job.timer
                delete job.timer

    # Add a scheduled job to the cron.
    add: (id, job) =>
        if @jobs[id]?
            if settings.cron.allowReplacing
                clearInterval @jobs[id].timer
            else
                logger.error "Expresser", "Cron.add", "Job #{id} already exists and 'allowReplacing' is false. Abort!"
                return

        # Only create the timer if `autoStart` is not false.
        setTimer job if job.autoStart isnt false

        # Add to the jobs list.
        @jobs[id] = job

    # Remove and stop a current job. If job does not exist, a warning will be logged.
    remove: (id) =>
        if not @jobs[id]?
            logger.debug "Expresser", "Cron.remove", "Job #{id} does not exist. Abort!"
            return

        clearTimeout @jobs[id]
        delete @jobs[id]


    # HELPERS
    # -------------------------------------------------------------------------

    # Helper to get a timer / interval based on the defined options.
    setTimer = (job) ->
        schedule = job.schedule
        callback = ->
            logger.debug "Expresser", "Cron", "Job #{job.id} trigger."
            job.callback job
            setTimer job

        # Set the timeout based on the defined schedule.
        job.timer = setTimeout callback, schedule


# Singleton implementation.
# -----------------------------------------------------------------------------
Cron.getInstance = ->
    @instance = new Cron() if not @instance?
    return @instance

module.exports = exports = Cron.getInstance()