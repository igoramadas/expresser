# EXPRESSER METRICS
# --------------------------------------------------------------------------
# Gather application metrics and generate JSON output to be used by
# monitoring systems.
# <!--
# @see settings.metrics
# -->
class Metrics

    lodash = null
    logger = null
    moment = null
    settings = null
    utils = null

    # This is where we store all metrics.
    metrics = {}

    # Timer to cleanup metrics.
    cleanupTimer = null

    # Init metrics and set up cleanup timer.
    init: =>
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        moment = @expresser.libs.moment
        settings = @expresser.settings
        utils = @expresser.utils

        cleanupTimer = setInterval @cleanup, settings.metrics.cleanupInterval * 60 * 1000

    # COUNTERS
    # -------------------------------------------------------------------------

    # Starts the counter for a specific metric. The data is optional.
    start: (id, data) ->
        obj = {}
        obj.id = id
        obj.data = data
        obj.startTime = moment().valueOf()

        # Create array of counters for the selected ID. Add metric to the beggining of the array.
        metrics[id] = [] if not metrics[id]?
        metrics[id].unshift obj

        logger.debug "Metrics.start", obj, data

        return obj

    # Ends the counter for the specified metric, with an optional error to be passed along.
    end: (obj, error) ->
        obj.endTime = moment().valueOf()
        obj.duration = obj.endTime - obj.startTime
        obj.error = error

        logger.debug "Metrics.end", obj

    # Get collected data for the specified metric.
    get: (id) ->
        return metrics[id]

    # Clean collected metrics by removing data older than X minutes (defined on settings).
    # Please note that this runs on s schedule so you shouldn't need to call it manually, in most cases.
    cleanup: ->
        logger.info "Metrics.cleanup"

        now = moment().valueOf()

        # Iterate metrics collection.
        for key, obj of metrics
            i = obj.length - 1

            # Iterate requests for the current metrics, last to first.
            while i >= 0
                diff = now - obj[i].startTime
                minutes = diff / 1000 / 60

                # Remove if verified as old. Otherwise, force finish the iteration.
                if minutes > settings.metrics.expireAfter or settings.metrics.expireAfter is 0
                    obj.pop()
                    i--
                else
                    i = -1

    # OUTPUT
    # -------------------------------------------------------------------------

    # Generate the JSON output with all metrics.
    output: ->
        logger.debug "Metrics.output", metrics

        result = {}
        keys = lodash.keys metrics

        # For each different metric...
        for key in keys
            obj = metrics[key]

            result[key] = {total_calls: obj.length}

            # Iterate intervals (for example 1m, 5m and 15m) to get specific stats.
            for interval in settings.metrics.outputIntervals
                result[key]["last_#{interval}min"] = getSummary obj, interval

            # Stats for last 3 calls.
            samples = []
            samples.push getLastSummary(obj[2]) if obj[2]?
            samples.push getLastSummary(obj[1]) if obj[1]?
            samples.push getLastSummary(obj[0]) if obj[0]?

            result[key].last_samples = samples

        return result

    # Helper to generate summary for the specified interval.
    getSummary = (obj, interval) ->
        now = moment().valueOf()
        values = []
        errorCount = 0
        i = 0

        # Iterate logged metrics, and get only if corresponding to the specified interval.
        while i < obj.length
            diff = now - obj[i].startTime
            minutes = diff / 1000 / 60

            if minutes <= interval
                values.push obj[i]
                errorCount++ if obj.error
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
        summary.avg = avg?.toFixed(2) or 0
        summary.min = lodash.min(durations) or 0
        summary.max = lodash.max(durations) or 0

        return summary

    # Helper to get summary for last calls.
    getLastSummary = (value) ->
        return {
            startTime: moment(value.startTime).format "MMM Do - HH:mm:ss.SSSS"
            duration: value.duration
            data: value.data
        }

# Singleton implementation.
# -----------------------------------------------------------------------------
Metrics.getInstance = ->
    @instance = new Metrics() if not @instance?
    return @instance

module.exports = exports = Metrics.getInstance()
