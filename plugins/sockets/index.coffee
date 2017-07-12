# EXPRESSER SOCKETS
# --------------------------------------------------------------------------
# Handles sockets communication using the module Socket.IO.
# ATTENTION! The Sockets module is started automatically by the App module.
# If you wish to disable it, set `Settings.sockets.enabled` to false.
# <!--
# @see settings.sockets
# -->
class Sockets

    priority: 3

    events = null
    lodash =  null
    logger = null
    settings = null

    # @property {Array} Holds a list of current event listeners.
    currentListeners: []

    # @property [Socket.IO Object] Exposes Socket.IO object to external modules.
    io: null

    # INIT
    # --------------------------------------------------------------------------

    # Init the Sockets plugin.
    init: ->
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        settings = @expresser.settings

        logger.debug "Sockets.init"
        events.emit "Sockets.before.init"

        @setEvents()

        events.emit "Sockets.on.init"
        delete @init

    # Bind events.
    setEvents: =>
        events.on "App.on.start", @bind

    # Bind the Socket.IO object to the Express app. This will also set the counter
    # to increase / decrease when users connects or disconnects from the app.
    # @param {Object} options Sockets init options.
    # @option options {Object} server The Express server object to bind to.
    bind: (server) =>
        return logger.notEnabled "Sockets", "bind" if not settings.sockets.enabled

        @io = require("socket.io") server

        # Listen to user connection count updates.
        @io.sockets.on "connection", (socket) =>
            socket.on "disconnect", @onDisconnect

            if settings.sockets.emitConnectionCount
                events.emit "Sockets.ConnectionCount", @getConnectionCount()

            # Bind all current event listeners.
            for listener in @currentListeners
                socket.on listener.key, listener.callback if listener?.callback?

    # EVENTS
    # ----------------------------------------------------------------------

    # Emit the specified key and data to clients.
    # @param {String} key The event key.
    # @param {Object} data The JSON data to be sent out to clients.
    emit: (key, data) ->
        return logger.notEnabled "Sockets", "emit" if not settings.sockets.enabled

        if not @io?
            logger.error "Sockets.emit", key, JSON.stringify(data).length + " bytes", "Sockets not initiated yet, abort!"
            throw new Error "Sockets not initiated (@io is not set)."

        logger.debug "Sockets.emit", key, data

        @io.emit key, data

    # Listen to a specific event. If `onlyNewClients` is true then it won't listen to that particular
    # event from currently connected clients.
    # @param {String} key The event key.
    # @param {Method} callback The callback to be called when key is triggered.
    # @param {Boolean} onlyNewClients Optional, if true, listen to event only from new clients.
    listenTo: (key, callback, onlyNewClients) ->
        return logger.notEnabled "Sockets", "listenTo" if not settings.sockets.enabled

        if not @io?.sockets?
            logger.error "Sockets.listenTo", key, "Sockets not initiated yet, abort!"
            throw new Error "Sockets not initiated (@io is not set)."

        onlyNewClients = false if not onlyNewClients?
        @currentListeners.push {key: key, callback: callback}

        logger.debug "Sockets.listenTo", key, callback, onlyNewClients

        if not onlyNewClients
            for key, socket of @io.sockets.connected
                socket.on key, callback

    # Stops listening to the specified event key.
    # @param {String} key The event key.
    # @param {Object} callback The callback to stop triggering.
    stopListening: (key, callback) ->
        for socketKey, socket of @io.sockets.connected
            if callback?
                socket.removeListener key, callback
            else
                socket.removeAllListeners key

        # Remove binding from the currentListeners collection.
        for listener in @currentListeners
            if listener.key is key and (listener.callback is callback or not callback?)
                listener = null

        logger.debug "Sockets.stopListening", key

    # Remove invalid and expired event listeners.
    compact: =>
        @currentListeners = lodash.compact @currentListeners

    # HELPERS
    # ----------------------------------------------------------------------

    # Get how many users are currenly connected to the app.
    getConnectionCount: =>
        return 0 if not @io?.sockets?
        return Object.keys(@io.sockets.connected).length

    # When user disconnects, emit an event with the new connection count to all clients.
    onDisconnect: =>
        logger.debug "Sockets.onDisconnect"

        if settings.sockets.emitConnectionCount
            events.emit "Sockets.ConnectionCount", @getConnectionCount()

# Singleton implementation
# --------------------------------------------------------------------------
Sockets.getInstance = ->
    @instance = new Sockets() if not @instance?
    return @instance

module.exports = exports = Sockets.getInstance()
