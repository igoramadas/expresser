# EXPRESSER EVENTS
# -----------------------------------------------------------------------------
# Central event manager to dispatch events to all Expresser modules.
# This module acts as a wrapper to Node's EventEmitter class.
class Events
    newInstance: -> return new Events()

    evt = require "events"
    emitter = new evt.EventEmitter()

    # Set event emitter defaults.
    constructor: ->
        emitter.setMaxListeners 20

    # METHODS
    # -------------------------------------------------------------------------

    # Emit a new event. The first argument is the event ID, all others are
    # passed to the event emitter. Only if `settings.events.enabled` is true!
    # @param {String} id The event ID.
    # @param {Arguments} args Arguments to be passed to the emitter.
    # @return {Object} Returns itself.
    emit: (id, args) ->
        emitter.emit.apply emitter, arguments
        return this

    # Bind a specific callback to an event ID.
    # @param {String} id The event ID.
    # @param {Method} callback The callback to be triggered.
    # @param {Boolean} prepend If true, prepend the callback to the list, default is false.
    # @return {Object} Returns itself.
    on: (id, callback, prepend = false) ->
        if prepend is true
            emitter.prependListener id, callback
        else
            emitter.addListener id, callback
        return this

    # Bind a specific one time callback to an event ID.
    # @param {String} id The event ID.
    # @param {Method} callback The callback to be triggered only once.
    # @param {Boolean} prepend If true, prepend the callback to the list, default is false.
    # @return {Object} Returns itself.
    once: (id, callback, prepend = false) ->
        if prepend is true
            emitter.prependOnceListener id, callback
        else
            emitter.once id, callback
        return this

    # Remove a specific callback from the listeners related to an event ID.
    # @param {String} id The event ID.
    # @param {Method} callback The callback to be removed.
    # @return {Object} Returns itself.
    off: (id, callback) ->
        emitter.removeListener id, callback
        return this

    # Returns an array with all listeners attached to the specified event ID.
    # @param {String} id The event ID.
    # @return {Object} Returns an array with listeners.
    listeners: (id) ->
        return emitter.listeners id

# Singleton implementation
# -----------------------------------------------------------------------------
Events.getInstance = ->
    @instance = new Events() if not @instance?
    return @instance

module.exports = Events.getInstance()
