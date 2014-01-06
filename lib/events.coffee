# EXPRESSER EVENTS
# -----------------------------------------------------------------------------
# Central event manager to dispatch events to all Expresser modules.
# This module acts as a wrapper to Node's EventEmitter class.
class Events

    evt = require "events"
    emitter = new evt.EventEmitter()

    # METHODS
    # -------------------------------------------------------------------------

    # Emit a new event. The first argument is the event ID, all others are
    # passed to the event emitter.
    # @param [String] id The event ID.
    # @param [Arguments] args Arguments to be passed to the emitter.
    # @return Returns itself so calls can be chained.
    emit: (id, args) =>
        emitter.emit.apply emitter, arguments
        return this

    # Bind a specific callback to an event ID.
    # @param [String] id The event ID.
    # @param [Method] callback The callback to be triggered.
    # @return Returns itself so calls can be chained.
    on: (id, callback) =>
        emitter.addListener id, callback
        return this

    # Remove a specific callback from the listeners related to an event ID.
    # @param [String] id The event ID.
    # @param [Method] callback The callback to be removed.
    # @return Returns itself so calls can be chained.
    off: (id, callback) =>
        emitter.removeListener id, callback
        return this

# Singleton implementation.
# -----------------------------------------------------------------------------
Events.getInstance = ->
    @instance = new Events() if not @instance?
    return @instance

module.exports = exports = Events.getInstance()