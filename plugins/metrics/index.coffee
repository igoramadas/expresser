# EXPRESSER METRICS
# --------------------------------------------------------------------------
percentile = require "./percentile.coffee"

events = null
lodash = null
logger = null
moment = null
settings = null
utils = null

# This is where we store all metrics.
metrics = {}

# Timer to cleanup metrics.
cleanupTimer = null

###
# To gather application metrics and generate JSON output to be used by
# monitoring systems.
###
class Metrics
    priority: 2

    ##
    # HTTP server module exposed to other modules.
    # @property
    # @type HttpServer
    httpServer: require "./httpserver.coffee"

    ###
    # Init metrics and set up cleanup timer.
    ###
    init: ->
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        moment = @expresser.libs.moment
        settings = @expresser.settings
        utils = @expresser.utils

        logger.debug "Metrics.init"

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

    # METHODS
    # -------------------------------------------------------------------------

    # Get collected data for the specified metric.
    # @param {String} id ID of the metric.
    get: (id) ->
        return metrics[id]

    ###
    # Starts the counter for a specific metric. The data is optional.
    # @param {String} id ID of the metric to be started.
    # @param {Object} tag Sets a tag / label to the metric, for instance the parameters used on that particular method call.
    # @param {Number} expiresIn Optional, metric should expire in these amount of milliseconds if not ended.
    # @return {Object} Returns the metric object to be used later on `end`.
    ###
    start: (id, tag, expiresIn) ->
        logger.debug "Metrics.start", obj, tag, expiresIn

        if not settings.metrics.enabled
            return logger.notEnabled "Metrics"

        expiresIn = 0 if not expiresIn?

        obj = {}
        obj.id = id
        obj.tag = tag
        obj.startTime = moment().valueOf()

        # Append instance methods.
        obj.end = @end
        obj.setData = @setData

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

    ###
    # Ends the counter for the specified metric, with an optional error to be passed along.
    # @param {Object} obj The metric object started previsouly on `start`.
    # @param {Object} error Optional error that ocurred while processing the metric.
    ###
    end: (obj, error) ->
        if not obj?
            obj = this
        else if not error? and not obj.id and not obj.startTime
            error = obj
            obj = this

        obj.endTime = moment().valueOf()
        obj.duration = obj.endTime - obj.startTime

        # Only append error if there was one.
        if error?
            obj.error = error

        # Clear the expiry timeout only if there's one.
        if obj.timeout?
            clearTimeout obj.timeout
            delete obj.timeout

        logger.debug "Metrics.end", obj
        return true

    ###
    # Adds extra data / stats to the metric object.
    # @param {Object} obj The metric object started previsouly on `start`.
    # @param {String} key The data key or label.
    # @param {Number} value The data value.
    ###
    setData: (obj, key, value) ->
        if not obj?
            obj = this
        else if not value? and not obj.id and not obj.startTime
            value = key
            key = obj
            obj = this

        obj.data = {} if not obj.data?
        obj.data[key] = value

    # CLEANUP
    # -------------------------------------------------------------------------

    ###
    # Clean collected metrics by removing data older than X minutes (defined on settings).
    # Please note that this runs on s schedule so you shouldn't need to call it manually, in most cases.
    ###
    cleanup: ->
        logger.debug "Metrics.cleanup"

        if not settings.metrics.enabled
            return logger.notEnabled "Metrics"

        now = moment().valueOf()
        keyCounter = 0

        # Hold empty metric IDs.
        emptyIds = []

        # Iterate metrics collection.
        try
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
        catch ex
            logger.error "Metrics.cleanup", ex

        # Delete empty metrics if enabled on settings.
        if settings.metrics.cleanupEmpty and emptyIds.length > 0
            for key in emptyIds
                delete metrics[key]

        if counter > 0 and keyCounter > 0
            logger.info "Metrics.cleanup", "Removed #{counter} records from #{keyCounter} keys."

    # OUTPUT
    # -------------------------------------------------------------------------

    ###
    # Generate the JSON output with all metrics.
    # @param {Object} options Options to filter the output. Available options are same as settings.metrics.
    # @return {Object} JSON output with relevant metrics.
    ###
    output: (options) =>
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
            if not options.keys? or options?.keys?.indexOf(key) >= 0
                obj = metrics[key]

                result[key] = {total_calls: obj.length}

                # Iterate intervals (for example 1m, 5m and 15m) to get specific stats.
                for interval in options.intervals
                    result[key]["last_#{interval}min"] = @summary.get options, obj, interval

                # Include last samples?
                if options.includeLastSamples > 0
                    samples = []
                    s = 0

                    while s < options.includeLastSamples
                        samples.push @summary.getLast(obj[s]) if obj[s]?
                        s++

                    result[key].last_samples = samples

        logger.debug "Metrics.output", options, result

        return result

    ###
    # Summary helper methods.
    # @private
    ###
    summary: {

        ###
        # Generate summary for the specified object and interval.
        ###
        get: (options, obj, interval) ->
            now = moment().valueOf()
            values = []
            errorCount = 0
            expiredCount = 0
            i = 0

            # Consider we don't have extra data by default.
            dataKeys = []

            # Iterate logged metrics, and get only if corresponding to the specified interval.
            while i < obj.length
                diff = now - obj[i].startTime
                minutes = diff / 1000 / 60

                if minutes <= interval
                    values.push obj[i]

                    # Increment error and expired count.
                    errorCount++ if obj[i].error
                    expiredCount++ if obj[i].expired

                    # Check if extra data was passed, if so, append to the dataKeys list.
                    objData = obj[i].data

                    if objData?
                        dataKeys = lodash.concat dataKeys, lodash.keys(objData)

                    i++
                else
                    i = obj.length

            # Get relevant durations and data from collection.
            durations = lodash.map values, "duration"
            data = lodash.map values, "data"
            avg = lodash.mean durations
            avg = 0 if isNaN avg

            # Create a summary with the important stats for each metric.
            result = {}
            result.calls = values.length
            result.errors = errorCount
            result.expired = expiredCount
            result.min = lodash.min(durations) or 0
            result.max = lodash.max(durations) or 0
            result.avg = avg or 0
            result.avg = Math.round result.avg

            # Calculate metrics for extra passed data.
            if dataKeys.length > 0
                dataKeys = lodash.uniq dataKeys

                result.data = {}

                for key in dataKeys
                    value = lodash.map data, key

                    result.data[key] = {
                        min: lodash.min value
                        max: lodash.max value
                        total: lodash.sum value
                    }

            # Get percentiles based on settings.
            if options.percentile?.length > 0
                for perc in options.percentiles
                    result["p#{perc}"] = percentile.calculate durations, perc

            return result

        ###
        # Helper to get summary for last calls.
        ###
        getLast: (value) ->
            if value?.startTime?
                try
                    result = {
                        startTime: value.startTime
                        duration: value.duration
                    }

                    # Append tag and data, if any.
                    result.tag = value.tag if value.tag?
                    result.data = value.data if value.data?

                    return result
                catch ex
                    logger.error "Metrics.getLast", "Start time #{value.startTime}", ex

            return {data: "Invalid metric"}
    }

# Singleton implementation
# -----------------------------------------------------------------------------
Metrics.getInstance = ->
    @instance = new Metrics() if not @instance?
    return @instance

module.exports = exports = Metrics.getInstance()
