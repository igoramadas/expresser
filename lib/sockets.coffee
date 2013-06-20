# EXPRESSER SOCKETS
# --------------------------------------------------------------------------
# Handles sockets communication using the module Socket.IO.
# Parameters on [settings.html](settings.coffee): Settings.Sockets

# ATTENTION!
# The Sockets module is started automatically by the App module. If you wish to
# disable it, set `Settings.Sockets.enabled` to false.

class Sockets

    lodash = require "lodash"
    logger = require "./logger.coffee"
    settings = require "./settings.coffee"

    # Holds a list of current event listeners.
    currentListeners: null

    # Exposes the Socket.IO to external modules.
    io: null


    # INIT
    # --------------------------------------------------------------------------

    # Bind the Socket.IO object to the Express app. This will also set
    # the counter to increase / decrease when users connects or
    # disconnects from the app.
    init: (server) =>
        env = process.env
        @currentListeners = []

        if not server?
            logger.error "Expresser", "Sockets.init", "App server is invalid. Abort!"
            return

        @io = require("socket.io").listen server

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
                socket.on(listener.key, listener.callback) if listener?


    # EVENTS
    # ----------------------------------------------------------------------

    # Emit the specified key / data to clients.
    emit: (key, data) =>
        @io.sockets.emit key, data

        if settings.general.debug
            logger.info "Expresser", "Sockets.emit", key, JSON.stringify(data).length + " bytes"

    # Listen to a specific event. If `onlyNewClients` is true then it won't listen to that particular
    # event from currently connected clients.
    listenTo: (key, callback, onlyNewClients) =>
        return if not callback?

        onlyNewClients = false if not onlyNewClients?
        @currentListeners.push {key: key, callback: callback}

        if not onlyNewClients
            for socketKey, socket of @io.sockets.manager.open
                socket.on key, callback

        if settings.general.debug
            logger.info "Expresser", "Sockets.listenTo", key

    # Stops listening to the specified event key.
    stopListening: (key, callback) =>
        for socketKey, socket of @io.sockets.manager.open
            if callback?
                socket.removeListener key, callback
            else
                socket.removeAllListeners key

        # Remove binding from the currentListeners collection.
        for listener in @currentListeners
            if listener.key is key and (listener.callback is callback or not callback?)
                listener = null

        if settings.general.debug
            logger.info "Expresser", "Sockets.stopListening", key

    # Remove invalid and expired event listeners.
    compact: =>
        @currentListeners = lodash.compact @currentListeners


    # HELPERS
    # ----------------------------------------------------------------------

    # Helper to get how many users are currenly connected to the app.
    getConnectionCount: =>
        return Object.keys(@io.sockets.manager.open).length

    # When user disconnects, emit an event with the new connection count to all clients.
    onDisconnect: =>
        count = @getConnectionCount()
        if settings.general.debug
            logger.info "Expresser", "Sockets.onDisconnect", "New count: #{count}."


# Singleton implementation
# --------------------------------------------------------------------------
Sockets.getInstance = ->
    @instance = new Sockets() if not @instance?
    return @instance

module.exports = exports = Sockets.getInstance()