# EXPRESSER CRON JOB
# -----------------------------------------------------------------------------
lodash = require "lodash"
moment = require "moment"
logger = null

###
# Represents a cron job.
###
class CronJob

    constructor: (parent, options) ->
        logger = parent.expresser.logger

        @[key] = value for key, value of options

        @startTime = options.startTime or moment 0
        @endTime = options.endTime or moment 0

    # METHODS
    # -------------------------------------------------------------------------

    ###
    # Starts the job timer. Please note that if you call start on a job that was
    # already started, it will clear and restart the timer(s) based on the job schedule.
    # @return {Moment} Date and time of the next scheduled run.
    ###
    start: =>
        logger.info "CronJob.start", @id

        callback = @getCallback()

        # Get the correct schedule value.
        if not lodash.isNumber @schedule
            schedule = moment.duration(@schedule).asMilliseconds()

        # Make sure timer is not running.
        clearTimeout @timer if @timer?

        # Set the timeout based on the defined schedule.
        timeout = @getTimeout()
        @timer = setTimeout callback, timeout
        @nextRun = moment().add timeout, "ms"

        return timeout

    ###
    # Stops the job by clearing the timeout.
    ###
    stop: =>
        logger.info "CronJob.stop", @id

        clearTimeout @timer if @timer?
        @timer = null

    # HELPERS
    # -------------------------------------------------------------------------

    ###
    # Helper to prepare and get the job callback function.
    # @private
    ###
    getCallback: =>
        callback = =>
            logger.info "CronJob.callback", @id

            @timer = null
            @startTime = moment()
            @endTime = moment()

            try
                # The parameters can be force set using "params".
                # If not present, pass the job itself to the callback instead.
                if @params
                    @callback.apply this, @params
                else
                    @callback this

                # Job end time should be set on the callback, but if it wasn't, we force set it here.
                @endTime = moment() if @startTime is @endTime
            catch ex
                logger.error "CronJob.callback", @id, ex.message, ex.stack

            # Only reset timer if once is not true.
            @start() if not @once

        # Return generated callback.
        return callback

    ###
    # Helper to get the timeout value in milliseconds till the next job callback.
    # @private
    ###
    getTimeout: =>
        now = moment()
        nextDate = moment()

        # If `schedule` is not an array, parse it as integer / seconds.
        if lodash.isNumber @schedule or lodash.isString @schedule
            timeout = moment().add(@schedule, "ms").valueOf() - now.valueOf()
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

# Exports
# --------------------------------------------------------------------------
module.exports = CronJob
