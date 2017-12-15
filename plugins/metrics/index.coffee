# EXPRESSER METRICS
# --------------------------------------------------------------------------
# Gather application metrics and generate JSON output to be used by
# monitoring systems.
# <!--
# @see settings.metrics
# -->
class Metrics

    priority: 2

    events = null
    lodash = null
    logger = null
    moment = null
    percentile = require "./percentile.coffee"
    settings = null
    utils = null

    # This is where we store all metrics.
    metrics = {}

    # Timer to cleanup metrics.
    cleanupTimer = null

    # HTTP server module exposed to other modules.
    httpServer: require "./httpserver.coffee"

    # Init metrics and set up cleanup timer.
    init: ->
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        moment = @expresser.libs.moment
        settings = @expresser.settings
        utils = @expresser.utils

        logger.debug "Metrics.init"
        events.emit "Metrics.before.init"

        # Make sure settings are valid.
        settings.metrics.httpServer = {} if not settings.metrics.httpServer?
        settings.metrics.intervals = [] if not settings.metrics.intervals?
        settings.metrics.percentiles = [] if not settings.metrics.percentiles?

        # Schedule the cleanup job.
        cleanupTimer = setInterval @cleanup, settings.metrics.cleanupInterval * 60 * 1000

        # Init the HTTP server module. Start if a valid port was set.
        @httpServer.init this
        @httpServer.start() if settings.metrics.httpServer.port? and settings.metrics.httpServer.autoStart

        events.emit "Metrics.on.init"
        delete @init

    # COUNTERS
    # -------------------------------------------------------------------------

    # Starts the counter for a specific metric. The data is optional.
    # @param {String} id ID of the metric to be started.
    # @param {Object} data Additional info about the current metric (URL data, for example).
    # @param {Number} expiresIn Optional, metric should expire in these amount of milliseconds if not ended.
    # @return {Object} Returns the metric object to be used later on `end`.
    start: (id, data, expiresIn) ->
        logger.debug "Metrics.start", obj, data, expiresIn

        if not settings.metrics.enabled
            return logger.notEnabled "Metrics"

        expiresIn = 0 if not expiresIn?

        obj = {}
        obj.id = id
        obj.data = data
        obj.startTime = moment().valueOf()

        # Should the metric expire (value in milliseconds)?
        if expiresIn > 0
            expiryTimeout = =>
                logger.debug "Metrics.start", "Expired!", obj
                obj.expired = true
                @end obj

            obj.timeout = setTimeout expiryTimeout, expiresIn

        # Create array of counters for the selected ID. Add metric to the beggining of the array.
        metrics[id] = [] if not metrics[id]?
        metrics[id].unshift obj

        return obj

    # Ends the counter for the specified metric, with an optional error to be passed along.
    # @param {Object} obj The metric object started previsouly on `start`.
    # @param {Object} error Optional error that ocurred while processing the metric.
    end: (obj, error) ->
        obj.endTime = moment().valueOf()
        obj.duration = obj.endTime - obj.startTime
        obj.error = error

        # Clear the expiry timeout only if there's one.
        if obj.timeout?
            clearTimeout obj.timeout
            delete obj.timeout

        logger.debug "Metrics.end", obj

    # Get collected data for the specified metric.
    # @param {String} id ID of the metric.
    get: (id) ->
        return metrics[id]

    # CLEANUP
    # -------------------------------------------------------------------------

    # Clean collected metrics by removing data older than X minutes (defined on settings).
    # Please note that this runs on s schedule so you shouldn't need to call it manually, in most cases.
    cleanup: ->
        logger.debug "Metrics.cleanup"

        if not settings.metrics.enabled
            return logger.notEnabled "Metrics"

        now = moment().valueOf()
        keyCounter = 0

        # Hold empty metric IDs.
        emptyIds = []

        # Iterate metrics collection.
        for key, obj of metrics
            i = obj.length - 1
            counter = 0
            keyCounter++

            if obj.length < 1
                emptyIds.push key

            # Iterate requests for the current metrics, last to first.
            while i >= 0
                diff = now - obj[i].startTime
                minutes = diff / 1000 / 60

                # Remove if verified as old. Otherwise, force finish the iteration.
                if minutes > settings.metrics.expireAfter or settings.metrics.expireAfter is 0
                    obj.pop()
                    i--
                    counter++
                else
                    i = -1

        # Delete empty metrics if enabled on settings.
        if settings.metrics.cleanupEmpty and emptyIds.length > 0
            for key in emptyIds
                delete metrics[key]

        if counter > 0 and keyCounter > 0
            logger.info "Metrics.cleanup", "Removed #{counter} records from #{keyCounter} keys."

    # OUTPUT
    # -------------------------------------------------------------------------

    # Generate the JSON output with all metrics.
    # @param {Object} options Options to filter the output. Available options are same as settings.metrics.
    # @return {Object} JSON output with relevant metrics.
    output: (options) ->
        logger.debug "Metrics.output", options
        utils.system.getInfo()

        # Get all metrics keys.
        keys = lodash.keys metrics

        # Set default options.
        options = {} if not options?
        options = lodash.defaultsDeep options, settings.metrics
        options.keys = keys if not options.keys?

        result = {}

        # Add server info to the output?
        if options.systemMetrics?.fields?.length > 0
            serverInfo = utils.system.getInfo()
            serverKey = options.systemMetrics.key
            result[serverKey] = {}

            for f in options.systemMetrics.fields
                result[serverKey][f] = serverInfo[f]

        # For each different metric...
        for key in keys
            if not options?.keys? or options?.keys?.indexOf(key) >= 0
                obj = metrics[key]

                result[key] = {total_calls: obj.length}

                # Iterate intervals (for example 1m, 5m and 15m) to get specific stats.
                for interval in options.intervals
                    result[key]["last_#{interval}min"] = getSummary options, obj, interval

                # Stats for last 3 calls.
                samples = []
                samples.push getLastSummary(obj[2]) if obj[2]?
                samples.push getLastSummary(obj[1]) if obj[1]?
                samples.push getLastSummary(obj[0]) if obj[0]?

                result[key].last_samples = samples

        logger.debug "Metrics.output", options, result

        return result

    # Helper to generate summary for the specified interval.
    getSummary = (options, obj, interval) ->
        now = moment().valueOf()
        values = []
        errorCount = 0
        expiredCount = 0
        i = 0

        # Iterate logged metrics, and get only if corresponding to the specified interval.
        while i < obj.length
            diff = now - obj[i].startTime
            minutes = diff / 1000 / 60

            if minutes <= interval
                values.push obj[i]
                errorCount++ if obj[i].error
                expiredCount++ if obj[i].expired
                i++
            else
                i = obj.length

        # All we care about is the duration for the relevant requests.
        durations = lodash.map values, "duration"
        avg = lodash.mean durations
        avg = 0 if isNaN avg

        # Create a summary with the important stats for each metric.
        summary = {}
        summary.calls = values.length
        summary.errors = errorCount
        summary.expired = expiredCount
        summary.min = lodash.min(durations) or 0
        summary.max = lodash.max(durations) or 0
        summary.avg = avg or 0
        summary.avg = Math.round summary.avg

        # Get percentiles based on settings.
        for perc in options.percentiles
            summary["p#{perc}"] = percentile.calculate durations, perc

        return summary

    # Helper to get summary for last calls.
    getLastSummary = (value) ->
        return {
            startTime: moment(value.startTime).format "MMM Do - HH:mm:ss.SSSS"
            duration: value.duration
            data: value.data
        }

# Singleton implementation
# -----------------------------------------------------------------------------
Metrics.getInstance = ->
    @instance = new Metrics() if not @instance?
    return @instance

module.exports = exports = Metrics.getInstance()
