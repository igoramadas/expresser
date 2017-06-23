# EXPRESSER CRON
# -----------------------------------------------------------------------------
# Handle scheduled cron jobs. You can use intervals (seconds) or specific
# times to trigger jobs, and the module will take care of setting the proper timers.
# Jobs are added using "job" objects with id, schedule, callback and other options.
#
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
#
# This module will load scheduled tasks from the "cron.json" file if the
# setting `loadOnInit` is true.
#
# @see settings.cron
# -->
class Cron

    priority: 5

    events = null
    fs = require "fs"
    lodash = null
    logger = null
    moment = null
    path = require "path"
    settings = null
    utils = null

    # @property {Array} The jobs collection, please do not edit this object manually!
    jobs: []

    # INIT
    # -------------------------------------------------------------------------

    # Init the cron manager. If `loadOnInit` setting is true, the `cron.json`
    # file will be parsed and loaded straight away (if there's one).
    init: =>
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        moment = @expresser.libs.moment
        settings = @expresser.settings
        utils = @expresser.utils

        logger.debug "Cron.init"
        events.emit "Cron.before.init"

        @setEvents()

        @load settings.cron.defaultFilename if settings.cron.loadOnInit

        events.emit "Cron.on.init"
        delete @init

    # Bind events.
    setEvents: =>
        events.on "Cron.load", @load
        events.on "Cron.start", @start
        events.on "Cron.stop", @stop
        events.on "Cron.add", @add
        events.on "Cron.remove", @remove

    # Load jobs from the specified (default cron.json) file.
    # If `autoStart` is true, it will automatically call the `start` method after loading.
    # @param {String} filename Path to the JSON file containing jobs, optional, default is "cron.json".
    # @param {Object} options Options to be passed when loading cron jobs.
    # @option options {String} filename Name of file to be loaded (in case filename was not set on first parameter)
    # @option options {String} basePath Sets the base path of modules when requiring them.
    # @option options {Boolean} autoStart If true, call `start` after loading.
    load: (filename, options) =>
        logger.debug "Cron.load", filename, options
        return logger.notEnabled "Cron", "load" if not settings.cron.enabled

        # DEPRECATED!
        if lodash.isBoolean filename
            err = logger.deprecated "Cron.load(boolean)", "First parameter must be the filename of the cron file to be loaded, or options object."
            throw err

        # Set default options.
        options = filename if lodash.isObject filename
        options = lodash.defaults options, {autoStart: settings.cron.autoStart, basePath: settings.cron.basePath}

        # Make sure filename is set.
        filename = options.filename if not filename?

        # Get full path to the passed json file.
        filepath = utils.io.getFilePath filename

        # Found the cron json file? Read it.
        if filepath?
            basename = path.basename filepath
            cronJson = ""

            try
                cronJson = fs.readFileSync filepath, {encoding: settings.general.encoding}
                cronJson = utils.data.minifyJson cronJson
            catch ex
                err = "Could not parse #{filepath} as JSON. #{ex.name} #{ex.message}"
                logger.error "Cron.load", err
                throw {error: "Invalid JSON", message: err}

            # Iterate jobs, but do not add if job's `enabled` is false.
            for key, data of cronJson
                module = require(path.dirname(require.main.filename) + "/" + options.basePath + key)

                # Only proceed if the cronDisabled flag is not present on the module.
                # If no ID is set for the job, use module key + callback name.
                if module.cronDisabled isnt true
                    for d in data
                        if not d.enabled? or d.enabled
                            cb = module[d.callback]
                            job = d
                            job.filename = filename
                            job.module = key
                            job.id = key + "." + d.callback if not job.id?
                            job.callback = cb
                            job.timer = null
                            @add job
                        else
                            logger.info "Cron.load", filename, key, d.callback, "Job 'enabled' is false. Skip!"
                else
                    logger.info "Cron.load", filename, "Module has 'cronDisabled' set. Skip!"

            # Start all jobs automatically if `autoStart` is true.
            if options.autoStart
                if filename
                    @start {filename: filename}
                else
                    @start()

            logger.info "Cron.load", "#{basename} loaded.", options
        else
            err = "Cron file #{filename} not found."
            logger.error "Cron.load", err
            throw {error: "Not found", message: "Could not load cron file #{filename}."}

    # METHODS
    # -------------------------------------------------------------------------

    # Start the specified cron job. If no `id` is specified, all jobs will be started.
    # A filter can also be passed as an object. For example to start all jobs for
    # the module "email", use start({module: "email"}).
    # @param {String} idOrFilter The job id or filter, optional (if not specified, start everything).
    start: (idOrFilter) =>
        logger.debug "Cron.start", idOrFilter
        return logger.notEnabled "Cron", "start" if not settings.cron.enabled

        if not idOrFilter?
            logger.info "Cron.start", "All jobs"
            arr = @jobs

        if lodash.isString idOrFilter or lodash.isNumber idOrFilter
            logger.info "Cron.start", idOrFilter
            arr = lodash.find @jobs, {id: idOrFilter.toString()}
        else
            logger.info "Cron.start", idOrFilter
            arr = lodash.find @jobs, idOrFilter

        if not arr? or arr.length < 1
            filterString = idOrFilter
            filterString = JSON.stringify filterString, null, 0 if lodash.isObject filterString
            logger.warn "Cron.start", "No jobs matching #{filterString}."
            return {notFound: true}
        else
            for job in arr
                clearTimeout job.timer if job.timer?
                setTimer job

    # Stop the specified cron job. If no `id` is specified, all jobs will be stopped.
    # A filter can also be passed as an object. For example to stop all jobs for
    # the module "mymodule", use stop({module: "mymodule"}).
    # @param {String} idOrFilter The job id or filter, optional (if not specified, stop everything).
    stop: (idOrFilter) =>
        logger.debug "Cron.stop", idOrFilter

        if not idOrFilter?
            logger.info "Cron.stop", "All jobs"
            arr = @jobs

        if lodash.isString idOrFilter or lodash.isNumber idOrFilter
            logger.info "Cron.stop", idOrFilter
            arr = lodash.find @jobs, {id: idOrFilter.toString()}
        else
            logger.info "Cron.stop", idOrFilter
            arr = lodash.find @jobs, idOrFilter

        if not arr? or arr.length < 1
            filterString = idOrFilter
            filterString = JSON.stringify filterString, null, 0 if lodash.isObject filterString
            logger.warn "Cron.stop", "No jobs matching #{filterString}."
            return {notFound: true}
        else
            for job in arr
                clearTimeout job.timer if job.timer?
                job.timer = null

    # Add a scheduled job to the cron, passing a `job`.
    # You can also pass only the `job` if it has an id property.
    # @param {String} id The job ID, optional, overrides job.id in case it has one.
    # @param {Object} job The job object.
    # @option job {String} id The job ID, optional.
    # @option job [Integer, Array] schedule If a number assume it's the interval in seconds, otherwise a times array.
    # @option job {Method} callback The callback (job) to be triggered.
    # @option job {Boolean} once If true, the job will be triggered only once no matter which schedule it has.
    # @return {Object} Returns {error, job}, where job is the job object and error is the error message (if any).
    add: (job) =>
        logger.debug "Cron.add", job
        return logger.notEnabled "Cron", "add" if not settings.cron.enabled

        # Throw error if no `id` was provided.
        if not job.id? or job.id is ""
            err = "Job must have an ID. Please set the job.id property."
            logger.error "Cron.add", err
            throw {error: "Missing job ID", message: err}

        # Throw error if job callback is not a valid function.
        if not lodash.isFunction job.callback
            err = "Job #{job.id} callback is not a valid, please set job.callback to a valid Function."
            logger.error "Cron.add", err
            throw {error: "Missing job callback", message: err}

        # Find existing job.
        existing = lodash.find @jobs, {id: job.id}

        # Handle existing jobs.
        if existing?
            if settings.cron.allowReplacing
                clearTimeout existing.timer if existing.timer?
                existing.timer = null
            else
                err = "Job #{job.id} already exists and 'allowReplacing' is false. Abort!"
                logger.error "Cron.add", err
                throw {error: "Job exists", message: err}

        # Set `startTime` and `endTime` if not set.
        job.startTime = moment 0 if not job.startTime?
        job.endTime = moment 0 if not job.endTime?

        # Only create the timer if `autoStart` is not false, add to the jobs list.
        setTimer job if job.autoStart isnt false
        @jobs.push job

        return {job: job}

    # Remove and stop a current job. If job does not exist, a warning will be logged.
    # @param {String} id The job ID.
    remove: (id) =>
        existing = lodash.find @jobs, {id: id}

        # Job exists?
        if not existing?
            logger.warn "Cron.remove", "Job #{id} does not exist."
            return false

        # Clear timer and remove job from array.
        clearTimeout existing.timer if existing.timer?
        @jobs.splice existing

    # HELPERS
    # -------------------------------------------------------------------------

    # Helper to get the timeout value (ms) to the next job callback.
    # @private
    getTimeout = (job) ->
        now = moment()
        nextDate = moment()

        # If `schedule` is not an array, parse it as integer / seconds.
        if lodash.isNumber job.schedule or lodash.isString job.schedule
            timeout = moment().add(job.schedule, "s").valueOf() - now.valueOf()
        else
            minTime = "99:99:99"
            nextTime = "99:99:99"

            # Get the next and minimum times from `schedule`.
            for sc in job.schedule
                minTime = sc if sc < minTime
                nextTime = sc if sc < nextTime and sc > nextDate.format("HH:mm:ss")

            # If no times were found for today then set for tomorrow, minimum time.
            if nextTime is "99:99:99"
                nextDate = nextDate.add 1, "d"
                nextTime = minTime

            # Return the timeout.
            arr = nextTime.split ":"
            dateValue = [nextDate.year(), nextDate.month(), nextDate.date(), parseInt(arr[0]), parseInt(arr[1]), parseInt(arr[2])]
            timeout = moment(dateValue).valueOf() - now.valueOf()

        return timeout

    # Helper to prepare and get a job callback function.
    # @private
    getCallback = (job) ->
        callback = ->
            logger.debug "Cron", "Job #{job.id} trigger."
            job.timer = null
            job.startTime = moment()
            job.endTime = moment()

            try
                # The parameters can be force set using "params".
                # If not present, pass the job itself to the callback instead.
                if job.params
                    job.callback.apply job.callback, job.params
                else
                    job.callback job

                # Job end time should be set on the callback, but if it wasn't, we force set it here.
                job.endTime = moment() if job.startTime is job.endTime
            catch ex
                logger.error "Cron.getCallback", "Could not run job.", ex.message, ex.stack

            # Only reset timer if once is not true.
            setTimer job if not job.once

        # Return generated callback.
        return callback

    # Helper to get a timer / interval based on the defined options.
    # @private
    setTimer = (job) ->
        logger.debug "Cron.setTimer", job.id, job.description, job.schedule

        callback = getCallback job

        # Get the correct schedule / timeout value.
        schedule = job.schedule
        schedule = moment.duration(schedule).asMilliseconds() if not lodash.isNumber schedule

        # Make sure timer is not running.
        clearTimeout job.timer if job.timer?

        # Set the timeout based on the defined schedule.
        timeout = getTimeout job
        job.timer = setTimeout callback, timeout
        job.nextRun = moment().add timeout, "ms"

# Singleton implementation
# -----------------------------------------------------------------------------
Cron.getInstance = ->
    @instance = new Cron() if not @instance?
    return @instance

module.exports = exports = Cron.getInstance()
