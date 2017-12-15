# EXPRESSER CRON JOB
# -----------------------------------------------------------------------------
lodash = require "lodash"
moment = require "moment"

###
# Represents a cron job.
###
class CronJob

    constructor: (@id, options) ->
        @[key] = value for key, value of options

        @startTime = options.startTime or moment 0
        @endTime = options.endTime or moment 0

        # Should job auto start?
        @setTimer() if @autoStart

    # METHODS
    # -------------------------------------------------------------------------

    ###
    # Helper to get the timeout value (ms) to the next job callback.
    ###
    getTimeout: =>
        now = moment()
        nextDate = moment()

        # If `schedule` is not an array, parse it as integer / seconds.
        if lodash.isNumber @schedule or lodash.isString @schedule
            timeout = moment().add(@schedule, "s").valueOf() - now.valueOf()
        else
            minTime = "99:99:99"
            nextTime = "99:99:99"

            # Get the next and minimum times from `schedule`.
            for sc in @schedule
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

    ###
    # Helper to prepare and get a job callback function.
    ###
    getCallback: =>
        callback = =>
            logger.debug "CronJob", "Job #{@id} trigger."

            @timer = null
            @startTime = moment()
            @endTime = moment()

            try
                # The parameters can be force set using "params".
                # If not present, pass the job itself to the callback instead.
                if @params
                    @callback.apply @callback, @params
                else
                    @callback this

                # Job end time should be set on the callback, but if it wasn't, we force set it here.
                @endTime = moment() if @startTime is @endTime
            catch ex
                logger.error "CronJob.getCallback", "Could not run job #{@id}.", ex.message, ex.stack

            # Only reset timer if once is not true.
            @setTimer() if not @once

        # Return generated callback.
        return callback

    ###
    # Helper to get a timer / interval based on the defined options.
    ###
    setTimer: =>
        logger.debug "CronJob.setTimer", @id, @description, @schedule

        callback = @getCallback()

        # Get the correct schedule / timeout value.
        schedule = moment.duration(@schedule).asMilliseconds() if not lodash.isNumber @schedule

        # Make sure timer is not running.
        clearTimeout @timer if @timer?

        # Set the timeout based on the defined schedule.
        timeout = @getTimeout(job)
        @timer = setTimeout callback, timeout
        @nextRun = moment().add timeout, "ms"

module.exports = CronJob
