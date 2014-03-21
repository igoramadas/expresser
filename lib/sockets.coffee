# EXPRESSER SOCKETS
# --------------------------------------------------------------------------
# Handles sockets communication using the module Socket.IO.
# ATTENTION! The Sockets module is started automatically by the App module.
# If you wish to disable it, set `Settings.sockets.enabled` to false.
# <!--
# @see Settings.sockets
# -->
class Sockets

    lodash = require "lodash"
    logger = require "./logger.coffee"
    settings = require "./settings.coffee"

    # @property [Array] Holds a list of current event listeners.
    currentListeners: null

    # @property [Socket.IO Object] Exposes Socket.IO object to external modules.
    io: null

    # INIT
    # --------------------------------------------------------------------------

    # Bind the Socket.IO object to the Express app. This will also set the counter
    # to increase / decrease when users connects or disconnects from the app.
    # @param [Object] options Sockets init options.
    # @option options [Object] server The Express server object to bind to.
    init: (options) =>
        options = {server: options} if not options.server?
        @currentListeners = []

        if not options.server?
            logger.error "Sockets.init", "App server is invalid. Abort!"
            return

        @io = require("socket.io").listen options.server

        # Set transports.
        @io.set "transports", ["websocket", "xhr-polling", "htmlfile"]

        # On production, log only critical errors. On development, log almost everything.
        if settings.general.debug
            @io.set "log level", 2
        else
            @io.set "log level", 0
            @io.set "browser client minification"
            @io.set "browser client etag"
            @io.set "browser client gzip"

        # Listen to user connection count updates.
        @io.sockets.on "connection", (socket) =>
            @io.sockets.emit "connection-count", @getConnectionCount()
            socket.on "disconnect", @onDisconnect

            # Bind all current event listeners.
            for listener in @currentListeners
                socket.on listener.key, listener.callback if listener?

    # EVENTS
    # ----------------------------------------------------------------------

    # Emit the specified key and data to clients.
    # @param [String] key The event key.
    # @param [Object] data The JSON data to be sent out to clients.
    emit: (key, data) =>
        if @io?.sockets?
            @io.sockets.emit key, data
            logger.debug "Sockets.emit", key, JSON.stringify(data).length + " bytes"
        else
            logger.debug "Sockets.emit", key, "Sockets not initiated yet, abort!"

    # Listen to a specific event. If `onlyNewClients` is true then it won't listen to that particular
    # event from currently connected clients.
    # @param [String] key The event key.
    # @param [Method] callback The callback to be called when key is triggered.
    # @param [Boolean] onlyNewClients Optional, if true, listen to event only from new clients.
    listenTo: (key, callback, onlyNewClients) =>
        return if not callback?

        onlyNewClients = false if not onlyNewClients?
        @currentListeners.push {key: key, callback: callback}

        if not onlyNewClients
            for key, socket of @io.sockets.connected
                socket.on key, callback

        logger.debug "Sockets.listenTo", key

    # Stops listening to the specified event key.
    # @param [String] key The event key.
    # @param [Object] callback The callback to stop triggering.
    stopListening: (key, callback) =>
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
        return Object.keys(@io.sockets.connected).length

    # When user disconnects, emit an event with the new connection count to all clients.
    onDisconnect: =>
        count = @getConnectionCount()
        logger.debug "Sockets.onDisconnect", "New count: #{count}."


# Singleton implementation
# --------------------------------------------------------------------------
Sockets.getInstance = ->
    @instance = new Sockets() if not @instance?
    return @instance

module.exports = exports = Sockets.getInstance()