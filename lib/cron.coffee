# EXPRESSER CRON
# -----------------------------------------------------------------------------
# Handle scheduled cron jobs. You can use intervals (seconds) or specific
# times to trigger jobs, and the module will take care of setting the proper timers.
# Jobs are added using "job" objects with id, schedule, callback and other options.
# <!--
# @example Sample job object, alerts user every minute (60 seconds).
#   var myJob = {
#     id: "alertJob",
#     schedule: 60,
#     callback: function(job) { alertUser(mydata); }
#   }
# @example Sample job object, sends email every day at 10AM and 5PM.
#   var otherJob = {
#     id: "my mail job",
#     schedule: ["10:00:00", "17:00:00"],
#     callback: function(job) { mail.send(something); }
#   }
# @see Settings.cron
# -->
class Cron

    events = require "./events.coffee"
    fs = require "fs"
    lodash = require "lodash"
    logger = require "./logger.coffee"
    moment = require "moment"
    path = require "path"
    settings = require "./settings.coffee"
    utils = require "./utils.coffee"

    # @property [Object] The jobs container, please do edit this object manually!
    jobs: {}


    # CONSTRUCTOR AND INIT
    # -------------------------------------------------------------------------

    # Class constructor.
    constructor: ->
        @setEvents()

    # Bind event listeners.
    setEvents: =>
        events.on "cron.start", @start
        events.on "cron.stop", @stop

    # Init the cron manager. If `loadOnInit` is true, call `load` straight away.
    init: =>
        logger.debug "Cron.init"
        @load true if settings.cron.loadOnInit

    # Load jobs from the `cron.json` file. If `autoStart` is true, it will automatically
    # call the `start` method after loading.
    # @param [String] filename Path to the JSON file containing jobs, optional, default is "cron.json".
    # @param [Boolean] autoStart If true, call "start" after loading.
    load: (filename, autoStart) =>
        filename = "cron.json" if not filename? or filename is false or filename is ""
        filepath = utils.getConfigFilePath filename

        # Found the cron.json file? Read it.
        if filepath?
            logger.debug "Cron.load", filepath
            cronJson = fs.readFileSync filepath, {encoding: settings.general.encoding}

            # Parse the JSON data.
            cronJson = utils.minifyJson cronJson
            cronJson = JSON.parse cronJson

            # Add jobs from the parsed JSON array and auto start.
            @add job for job in cronJson
            @start() if autoStart

            logger.debug "Cron.load", "#{filename} loaded.", "Auto start: #{autoStart}"
        else
            logger.debug "Cron.load", "#{filename} not found."

    # METHODS
    # -------------------------------------------------------------------------

    # Start the specified cron job. If no `id` is specified, all jobs will be started.
    # @param [String] id The job unique id, optional (if not specified, start everything).
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
    # @param [String] id The job unique id, optional (if not specified, stop everything).
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
    # @param [String] id The job ID, optional, overrides job.id in case it has one.
    # @param [Object] job The job object.
    # @option job [String] id The job ID, optional.
    # @option job [Integer, Array] schedule If a number assume it's the interval in seconds, otherwise a times array.
    # @option job [Method] callback The callback (job) to be triggered.
    # @option job [Boolean] once If true, the job will be triggered only once no matter which schedule it has.
    # @return [Object] Returns {error, job}, where job is the job object and error is the error message (if any).
    add: (id, job) =>
        logger.debug "Cron.add", id, job

        if id? and not job?
            job = id
            id = null

        # If no `id` is passed, try getting it directly from the `job` object.
        id = job.id if not id?

        # Throw error if no `id` was provided.
        if not id? or id is ""
            errorMsg = "No 'id' was passed. Abort!"
            logger.error "Cron.add", errorMsg
            return {error: errorMsg}

        # Handle existing jobs.
        if @jobs[id]?
            if settings.cron.allowReplacing
                clearTimeout @jobs[id].timer
            else
                errorMsg = "Job #{id} already exists and 'allowReplacing' is false. Abort!"
                logger.error "Cron.add", errorMsg
                return {error: errorMsg}

        # Set `startTime` and `endTime` if not set.
        job.startTime = moment 0 if not job.startTime?
        job.endTime = moment 0 if not job.endTime?

        # Only create the timer if `autoStart` is not false.
        setTimer job if job.autoStart isnt false

        # Add to the jobs list.
        job.id = id
        @jobs[id] = job

        return {job: job}

    # Remove and stop a current job. If job does not exist, a warning will be logged.
    # @param [String] id The job ID.
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
        job.nextRun = moment().add "ms", timeout

        logger.debug "Cron.setTimer", job.id, timeout


# Singleton implementation.
# -----------------------------------------------------------------------------
Cron.getInstance = ->
    @instance = new Cron() if not @instance?
    return @instance

module.exports = exports = Cron.getInstance()