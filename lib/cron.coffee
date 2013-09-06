# EXPRESSER CRON
# -----------------------------------------------------------------------------
# Handle scheduled / cron jobs.

class Cron

    fs = require "fs"
    lodash = require "lodash"
    logger = require "./logger.coffee"
    moment = require "moment"
    path = require "path"
    settings = require "./settings.coffee"
    utils = require "./utils.coffee"

    # Jobs array object.
    jobs: {}


    # INIT AND LOAD FROM JSON
    # -------------------------------------------------------------------------

    # Init the cron jobs by reading the cron files, but only if `loadOnInit` is true.
    init: =>
        logger.debug "Expresser", "Cron.init"
        @load true if settings.cron.loadOnInit

    # Load jobs from the `cron.json` file. If `autoStart` is true, it will automatically
    # call the `start` method after load.
    load: (filename, autoStart) =>
        filepath = @getConfigFilePath filename

        # Found the cron.json file? Read it.
        if filepath?
            logger.debug "Expresser", "Cron.load", filepath

            try
                cronJson = fs.readFileSync filepath, {encoding: "utf8"}
            catch ex
                cronJson = fs.readFileSync filepath, {encoding: "ascii"}

            # Parse the JSON data.
            cronJson = utils.minifyJson cronJson
            cronJson = JSON.parse cronJson

            # Add jobs from the parsed JSON array, and auto start.
            @add job for job in cronJson
            @start() if autoStart

        else
            logger.debug "Expresser", "Cron.load", "#{filename} not found."

    # METHODS
    # -------------------------------------------------------------------------

    # Start the specified cron job. If no `id` is specified, all jobs will be started.
    start: (id) =>
        if id? and id isnt false and id isnt ""
            if @jobs[id]?
                logger.debug "Expresser", "Cron.start", id
                clearTimeout @jobs[id].timer if @jobs[id].timer?
                setTimer @jobs[id]
            else
                logger.debug "Expresser", "Cron.start", "Job #{id} does not exist. Abort!"
        else
            logger.debug "Expresser", "Cron.start"
            for job of @jobs
                setTimer job

    # Stop the specified cron job. If no `id` is specified, all jobs will be stopped.
    stop: (id) =>
        if id? and id isnt false and id isnt ""
            if @jobs[id]?
                logger.debug "Expresser", "Cron.stop", id
                clearTimeout @jobs[id].timer
                delete @jobs[id].timer
            else
                logger.debug "Expresser", "Cron.stop", "Job #{id} does not exist. Abort!"
        else
            logger.debug "Expresser", "Cron.stop"
            for job of @jobs
                clearTimeout job.timer
                delete job.timer

    # Add a scheduled job to the cron.
    add: (id, job) =>
        logger.debug "Expresser", "Cron.add", id, job

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
        callback = ->
            logger.debug "Expresser", "Cron", "Job #{job.id} trigger."
            job.callback job
            setTimer job

        # Get the correct schedule / timeout value.
        schedule = job.schedule
        schedule = moment.duration(schedule).asMilliseconds() if not lodash.isNumber schedule

        # Make sure timer is not running.
        clearTimeout job.timer if job.timer?

        # Set the timeout based on the defined schedule.
        job.timer = setTimeout callback, schedule


# Singleton implementation.
# -----------------------------------------------------------------------------
Cron.getInstance = ->
    @instance = new Cron() if not @instance?
    return @instance

module.exports = exports = Cron.getInstance()