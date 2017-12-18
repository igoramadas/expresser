# EXPRESSER CRON
# -----------------------------------------------------------------------------
fs = require "fs"
jobModel = require "./job.coffee"
path = require "path"
errors = null
events = null
lodash = null
logger = null
moment = null
settings = null
util = require "util"
utils = null

# Handle scheduled cron jobs. You can use intervals (seconds) or specific
# times to trigger jobs, and the module will take care of setting the proper timers.
# Jobs are added using "job" objects with id, schedule, callback and other options.
class Cron

    priority: 3

    ##
    # The jobs collection, this should be managed automatically by the module.
    # @property
    # @type Array
    jobs: []

    # INIT
    # -------------------------------------------------------------------------

    ###
    # Init the cron manager. If `loadOnInit` setting is true, the `cron.json`
    # file will be parsed and loaded straight away (if there's one).
    ###
    init: =>
        errors = @expresser.errors
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

    ###
    # Listen to Cron events.
    # @private
    ###
    setEvents: =>
        events.on "Cron.load", @load
        events.on "Cron.start", @start
        events.on "Cron.stop", @stop
        events.on "Cron.add", @add
        events.on "Cron.remove", @remove

    ###
    # Load jobs from the specified (default cron.json) file.
    # If `autoStart` is true, it will automatically call the `start` method after loading.
    # @param {String} filename Path to the JSON file containing jobs, optional, default is "cron.json".
    # @param {Object} options Options to be passed when loading cron jobs.
    # @option options {String} filename Name of file to be loaded (in case filename was not set on first parameter)
    # @option options {String} basePath Sets the base path of modules when requiring them.
    # @option options {Boolean} autoStart If true, call `start` after loading.
    ###
    load: (filename, options) =>
        logger.debug "Cron.load", filename, options

        if not settings.cron.enabled
            return logger.notEnabled "Cron"

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

                for d in data
                    if not d.enabled? or d.enabled
                        logger.debug "Cron.load", filename, d

                        jobOptions = {
                            id: d.id or key + "." + d.callback
                            callback: module[d.callback]
                            filename: filename
                            module: key
                            autoStart: options.autoStart
                        }

                        job = lodash.assign d, jobOptions
                        @add job
                    else
                        logger.warn "Cron.load", filename, key, d.callback, "Job 'enabled' is false. Skip!"

            logger.info "Cron.load", "#{basename} loaded.", options
        else
            err = "Cron file #{filename} not found."
            logger.error "Cron.load", err
            throw {error: "Not found", message: "Could not load cron file #{filename}."}

    # METHODS
    # -------------------------------------------------------------------------

    ###
    # Start the specified cron job. If no `id` is specified, all jobs will be started.
    # A filter can also be passed as an object. For example to start all jobs for
    # the module "email", use start({module: "email"}).
    # @param {CronJob|String|Object} obj The job object, id or filter, optional (if not specified, start everything).
    ###
    start: (filter) =>
        logger.debug "Cron.start", filter

        if not settings.cron.enabled
            return logger.notEnabled "Cron"

        if not filter?
            logger.info "Cron.start", "All jobs"
            arr = @jobs

        # Passing the job directly?
        else if filter.constructor?.name is "CronJob"
            arr = [filter]

        # Passing the job ID (string or number)?
        else if lodash.isString filter or lodash.isNumber filter
            logger.info "Cron.start", filter
            arr = lodash.find @jobs, {id: filter.toString()}

        # Passing an object with key / value pairs to filter jobs?
        else
            logger.info "Cron.start", filter
            arr = lodash.find @jobs, filter

        if not arr? or arr.length < 1
            filterString = filter
            filterString = JSON.stringify filterString, null, 0 if lodash.isObject filterString
            logger.warn "Cron.start", "No jobs matching #{filterString}."
            return {notFound: true}
        else
            for job in arr
                job.start()
                logger.info "Cron.start", "Started job", job.id

    ###
    # Stop the specified cron job. If no `id` is specified, all jobs will be stopped.
    # A filter can also be passed as an object. For example to stop all jobs for
    # the module "mymodule", use stop({module: "mymodule"}).
    # @param {CronJob|String|Object} filter The job object, id or filter, optional (if not specified, stop everything).
    ###
    stop: (filter) =>
        logger.debug "Cron.stop", filter

        if not filter?
            logger.info "Cron.stop", "All jobs"
            arr = @jobs

        # Passing the job directly?
        else if filter.constructor?.name is "CronJob"
            arr = [filter]

        # Passing the job ID (string or number)?
        else if lodash.isString filter or lodash.isNumber filter
            arr = lodash.find @jobs, {id: filter.toString()}

        # Passing an object with key / value pairs to filter jobs?
        else
            logger.info "Cron.stop", filter
            arr = lodash.find @jobs, filter

        if not arr? or arr.length < 1
            filterString = filter
            filterString = JSON.stringify filterString, null, 0 if lodash.isObject filterString
            logger.warn "Cron.stop", "No jobs matching #{filterString}."
            return {notFound: true}
        else
            for job in arr
                job.stop()
                logger.info "Cron.start", "Stopped job", job.id

    ###
    # Add a scheduled job to the cron, passing a `job`.
    # You can also pass only the `job` if it has an id property.
    # @param {String} id The job ID, optional, overrides job.id in case it has one.
    # @param {Object} job The job object.
    # @param {String} [job.id] The job ID, optional.
    # @param [Integer, Array] [job.schedule] If a number assume it's the interval in seconds, otherwise a times array.
    # @param {Method} [job.callback] The callback (job) to be triggered.
    # @param {Boolean} [job.once] If true, the job will be triggered only once no matter which schedule it has.
    # @return {CronJob} The job instance.
    ###
    add: (job) =>
        logger.debug "Cron.add", job

        if not settings.cron.enabled
            return logger.notEnabled "Cron"

        # Throw error if no `id` was provided.
        if not job.id? or job.id is ""
            return errors.throw "uniqueIdRequired", "Please set job.id."

        # Throw error if job callback is not a valid function.
        if not lodash.isFunction job.callback
            return errors.throw "callbackMustBeFunction", "Please set job.callback."

        # Find existing job.
        existing = lodash.find @jobs, {id: job.id}

        # Handle existing jobs.
        if existing?
            if settings.cron.allowReplacing
                clearTimeout existing.timer if existing.timer?
                existing.timer = null
            else
                return errors.throw "Job #{job.id} already exists and 'allowReplacing' is false."

        result = new jobModel this, job
        @jobs.push result

        # Auto starting the job is optional.
        @start result if job.autoStart

        return result

    ###
    # Remove and stop a current job. If job does not exist, a warning will be logged.
    # @param {String} id The job ID.
    # @return {Boolean} True if job removed, false if error or job does not exist.
    ###
    remove: (id) =>
        existing = lodash.find @jobs, {id: id}

        # Job exists?
        if not existing?
            logger.warn "Cron.remove", "Job #{id} does not exist."
            return false

        # Clear timer and remove job from array.
        clearTimeout existing.timer if existing.timer?
        existing.timer = null

        @jobs.splice existing

        return true

# Singleton implementation
# --------------------------------------------------------------------------
Cron.getInstance = ->
    @instance = new Cron() if not @instance?
    return @instance

module.exports = Cron.getInstance()
