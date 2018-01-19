# EXPRESSER EVENTS
# -----------------------------------------------------------------------------
evt = require "eventemitter3"

###
# Central event manager to dispatch events to other Expresser modules.
# Acts as a wrapper to Node's builtin EventEmitter class.
###
class Events
    newInstance: -> return new Events()

    ##
    # The underlying event emmiter.
    # @property
    # @type EventEmitter
    emitter: new evt()

    # METHODS
    # -------------------------------------------------------------------------

    ###
    # Emit a new event. Te frst argument is the event ID, all others are
    # passed to the event emitter.
    # @param {Arguments} args Arguments to be passed to the emitter.
    # @return {Object} Returns itself.
    ###
    emit: =>
        @emitter.emit.apply @emitter, arguments
        return this

    ###
    # Bind the specified callback to an event ID.
    # @param {String} id The event ID.
    # @param {Function} callback The callback to be triggered, mandatory.
    # @param {Boolean} prepend If true, prepend the callback to the list so it executes before others, default is false.
    # @return {Object} Returns itself.
    ###
    on: (id, callback, prepend = false) =>
        if prepend is true
            @emitter.prependListener id, callback
        else
            @emitter.addListener id, callback
        return this

    ###
    # Bind the specified "one time" callback to an event ID.
    # @param {String} id The event ID.
    # @param {Function} callback The callback to be triggered only once.
    # @param {Boolean} prepend If true, prepend the callback to the list so it executes before others, default is false.
    # @return {Object} Returns itself.
    ###
    once: (id, callback, prepend = false) =>
        if prepend is true
            @emitter.prependOnceListener id, callback
        else
            @emitter.once id, callback
        return this

    ###
    # Remove a specific callback from the listeners related to an event ID.
    # @param {String} id The event ID, mandatory.
    # @param {Function} callback The callback to be removed, mandatory.
    # @return {Object} Returns itself.
    ###
    off: (id, callback) =>
        @emitter.removeListener id, callback
        return this

    ###
    # Returns an array with all listeners attached to the specified event ID.
    # @param {String} id The event ID, mandatory.
    # @return {Object} Returns an array with listeners.
    ###
    listeners: (id) ->
        return @emitter.listeners id

# Singleton implementation
# -----------------------------------------------------------------------------
Events.getInstance = ->
    @instance = new Events() if not @instance?
    return @instance

module.exports = Events.getInstance()
