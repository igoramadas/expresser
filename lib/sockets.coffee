# EXPRESSER SOCKETS
# --------------------------------------------------------------------------
# Handles sockets communication using the module Socket.IO.
# Parameters on settings.coffee: Settings.Sockets

class Sockets

    logger = require "./logger.coffee"
    settings = require "./settings.coffee"


    # INIT
    # --------------------------------------------------------------------------

    # Bind the Socket.IO object to the Express app. This will also set
    # the counter to increase / decrease when users connects or
    # disconnects from the app.
    init: (server) =>
        if not server?
            logger.error "Expresser", "Sockets.init", "App server is not initialized. Abort!"
            return

        @io = require("socket.io").listen require("http").createServer server

        # Set transports.
        @io.set "transports", ["websocket", "xhr-polling", "htmlfile"]

        # On production, log only critical errors. On development, log almost everything.
        if settings.General.debug
            @io.set "log level", 2
        else
            @io.set "log level", 1
            @io.set "browser client minification"
            @io.set "browser client etag"
            @io.set "browser client gzip"

        # Listen to user connection count updates.
        @io.sockets.on "connection", (socket) =>
            @io.sockets.emit "connection-count", @getConnectionCount()
            socket.on "disconnect", @onDisconnect


    # EVENTS
    # ----------------------------------------------------------------------

    # Emit the specified key / data to clients.
    emit: (key, data) =>
        @io.sockets.emit key, data


    # HELPERS
    # ----------------------------------------------------------------------

    # Helper to get how many users are currenly connected to the app.
    getConnectionCount: =>
        count = Object.keys(@io.sockets.manager.open).length
        return count

    # When user disconnects, emit an event with the new connection count to all clients.
    onDisconnect: =>
        count = @getConnectionCount()
        if settings.General.debug
            logger.info "Expresser", "Sockets.onDisconnect", "New count: #{count}."


# Singleton implementation
# --------------------------------------------------------------------------
Sockets.getInstance = ->
    @instance = new Sockets() if not @instance?
    return @instance

module.exports = exports = Sockets.getInstance()