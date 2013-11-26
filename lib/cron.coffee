# EXPRESSER CRON
# -----------------------------------------------------------------------------
# Handle scheduled / cron jobs.
# To add a new scheduled job, use a job object with the following properties:
# id [optional]: a unique ID for the job.
# schedule:      interval in seconds or an array of times.
#                Ex: 60 (evey minute), 3600 (every hour), ["09:00:00", "15:00:00"] (every day at 9AM and 3PM).
# callback:      function to be called with the job, passing itself.
#                Ex: function (job) { alert(job.id); }
# once:          if true, execute this job only once.
# @see Settings.cron
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
        logger.debug "Cron.init"
        @load true if settings.cron.loadOnInit

    # Load jobs from the `cron.json` file. If `autoStart` is true, it will automatically
    # call the `start` method after load.
    load: (filename, autoStart) =>
        filepath = @getConfigFilePath filename

        # Found the cron.json file? Read it.
        if filepath?
            logger.debug "Cron.load", filepath

            try
                cronJson = fs.readFileSync filepath, {encoding: settings.general.encoding}
            catch ex
                cronJson = fs.readFileSync filepath, {encoding: "ascii"}

            # Parse the JSON data.
            cronJson = utils.minifyJson cronJson
            cronJson = JSON.parse cronJson

            # Add jobs from the parsed JSON array, and auto start.
            @add job for job in cronJson
            @start() if autoStart

        else
            logger.debug "Cron.load", "#{filename} not found."

    # METHODS
    # -------------------------------------------------------------------------

    # Start the specified cron job. If no `id` is specified, all jobs will be started.
    start: (id) =>
        if id? and id isnt false and id isnt ""
            if @jobs[id]?
                logger.debug "Cron.start", id
                clearTimeout @jobs[id].timer if @jobs[id].timer?
                setTimer @jobs[id]
            else
                logger.debug "Cron.start", "Job #{id} does not exist. Abort!"
        else
            logger.debug "Cron.start"
            for job of @jobs
                setTimer job

    # Stop the specified cron job. If no `id` is specified, all jobs will be stopped.
    stop: (id) =>
        if id? and id isnt false and id isnt ""
            if @jobs[id]?
                logger.debug "Cron.stop", id
                clearTimeout @jobs[id].timer
                delete @jobs[id].timer
            else
                logger.debug "Cron.stop", "Job #{id} does not exist. Abort!"
        else
            logger.debug "Cron.stop"
            for job of @jobs
                clearTimeout job.timer
                delete job.timer

    # Add a scheduled job to the cron, passing an `id` and `job`.
    # You can also pass only the `job` if it has an id property.
    add: (id, job) =>
        logger.debug "Cron.add", id, job

        if id? and not job?
            job = id
            id = null

        # If no `id` is passed, try getting it directly from the `job` object.
        id = job.id if not id?

        # Throw error if no `id` was provided.
        if not id? or id is ""
            logger.error "Cron.add", "No 'id' was passed. Abort!"
            return

        # Handle existing jobs.
        if @jobs[id]?
            if settings.cron.allowReplacing
                clearTimeout @jobs[id].timer
            else
                logger.error "Cron.add", "Job #{id} already exists and 'allowReplacing' is false. Abort!"
                return

        # Set `startTime` and `endTime` if not set.
        job.startTime = moment 0 if not job.startTime?
        job.endTime = moment 0 if not job.endTime?

        # Only create the timer if `autoStart` is not false.
        setTimer job if job.autoStart isnt false

        # Add to the jobs list.
        job.id = id
        @jobs[id] = job

    # Remove and stop a current job. If job does not exist, a warning will be logged.
    remove: (id) =>
        if not @jobs[id]?
            logger.debug "Cron.remove", "Job #{id} does not exist. Abort!"
            return

        clearTimeout @jobs[id]
        delete @jobs[id]


    # HELPERS
    # -------------------------------------------------------------------------

    # Helper to get the timeout value (ms) to the next job callback.
    getTimeout = (job) ->
        now = moment()

        # If `schedule` is not an array, parse it as integer / seconds.
        if not lodash.isArray job.schedule
            timeout = moment().add("s", job.schedule).valueOf() - now.valueOf()
        else
            minTime = "99:99:99"
            nextTime = "99:99:99"

            # Get the next and minimum times from `schedule`.
            for sc in job.schedule
                minTime = sc if sc < minTime
                nextTime = sc if sc < nextTime and sc > now.format("HH:mm:ss")

            # If no times were found for today then set for tomorrow, minimum time.
            if nextTime is "99:99:99"
                now = now.add "d", 1
                nextTime = minTime

            # Return the timeout.
            arr = nextTime.split ":"
            dateValue = [now.year(), now.month(), now.date(), parseInt(arr[0]), parseInt(arr[1]), parseInt(arr[2])]
            timeout moment(dateValue).valueOf() - now.valueOf()

        return timeout

    # Helper to get a timer / interval based on the defined options.
    setTimer = (job) ->
        callback = ->
            logger.debug "Cron", "Job #{job.id} trigger."
            job.startTime = moment()
            job.endTime = moment()
            job.callback job

            # Only reset timer if once is not true.
            setTimer job if not job.once

        # Get the correct schedule / timeout value.
        schedule = job.schedule
        schedule = moment.duration(schedule).asMilliseconds() if not lodash.isNumber schedule

        # Make sure timer is not running.
        clearTimeout job.timer if job.timer?

        # Set the timeout based on the defined schedule.
        timeout = getTimeout job
        job.timer = setTimeout callback, timeout

        logger.debug "Cron.setTimer", job.id, timeout


# Singleton implementation.
# -----------------------------------------------------------------------------
Cron.getInstance = ->
    @instance = new Cron() if not @instance?
    return @instance

module.exports = exports = Cron.getInstance()