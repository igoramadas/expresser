# EXPRESSER EVENTS
# -----------------------------------------------------------------------------
# Central event manager to dispatch events to all Expresser modules.
class Events

    evt = require "events"
    emitter = new evt.EventEmitter()


    # METHODS
    # -------------------------------------------------------------------------

    # Start the specified cron job. If no `id` is specified, all jobs will be started.
    # @param [String] id The job unique id, optional (if not specified, start everything).
    emit: (id) =>
        console.log id

    # Stop the specified cron job. If no `id` is specified, all jobs will be stopped.
    # @param [String] id The job unique id, optional (if not specified, stop everything).
    on: (id, callback) =>
        console.log id, callback

    off: (id, callback) =>


# Singleton implementation.
# -----------------------------------------------------------------------------
Events.getInstance = ->
    @instance = new Events() if not @instance?
    return @instance

module.exports = exports = Events.getInstance()