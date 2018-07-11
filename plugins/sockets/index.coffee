# EXPRESSER SOCKETS
# ------------------------------------------------------------------------------
events = null
lodash =  null
logger = null
settings = null
utils = null

###
# Handles sockets communication using the module Socket.IO.
###
class Sockets
    priority: 3

    ##
    # List of current event listeners.
    # @property
    # @type Array
    currentListeners: []

    ##
    # Promise function(socket) called on each client connection.
    # Result of this function must return a Boolean, and if
    # false, it will force close the connection and skip event bindings.
    # @property
    # @promise
    # @type Function
    onConnect: null

    ##
    # Exposes Socket.IO object to external modules.
    # @property
    # @type SocketIO
    io: null

    ##
    # Sockets initialized and ready to use?
    # @property
    # @type Boolean
    ready: false

    # INIT
    # --------------------------------------------------------------------------

    ###
    # Init the Sockets plugin.
    ###
    init: ->
        events = @expresser.events
        lodash = @expresser.libs.lodash
        logger = @expresser.logger
        settings = @expresser.settings
        utils = @expresser.utils

        logger.debug "Sockets.init"

        # Listen to app start so we can bind to the server.s
        events.on "App.on.start", @bind

        events.emit "Sockets.on.init"
        delete @init

    ###
    # Bind the Socket.IO object to the Express app. This will also set the counter
    # to increase / decrease when users connects or disconnects from the app.
    # @param {Object} server The HTTP(S) server object to bind to.
    ###
    bind: (server) =>
        if not settings.sockets.enabled
            return logger.notEnabled "Sockets"

        # Ready to go!
        @io = require("socket.io") server
        @ready = true

        # Listen to user connection count updates.
        @io.sockets.on "connection", (socket) =>
            ip = utils.browser.getClientIP socket
            logger.debug "Sockets.connection", "Connected", ip

            if @onConnect?
                try
                    valid = await @onConnect socket
                catch ex
                    logger.error "Sockets.connection", "onConnect", ip, ex
                    valid = false

                # Force disconnection if socket has not passed the onConnect() validation.
                if not valid
                    logger.warn "Sockets.connection", "Did not validate onConnect, will force disconnect"
                    return socket.disconnect()

            socket.on "disconnect", @onDisconnect

            if settings.sockets.emitConnectionCount
                events.emit "Sockets.ConnectionCount", @getConnectionCount()

            # Bind all current event listeners.
            for listener in @currentListeners
                socket.on listener.key, listener.callback if listener?.callback?

    ###
    # Close the Socket server.
    ###
    close: =>
        @io?.close () -> logger.info "Sockets.close"

    # EVENTS
    # ----------------------------------------------------------------------

    ###
    # Emit the specified key and data to clients.
    # @param {String} key The event key.
    # @param {Object} data The JSON data to be sent out to clients.
    ###
    emit: (key, data) =>
        if not settings?.sockets.enabled
            return logger.notEnabled "Sockets"
        else if not @ready
            return

        # Emit clone or actual object?
        if settings.sockets.clone
            obj = lodash.cloneDeep data
        else
            obj = data

        logger.debug "Sockets.emit", key, obj

        @io.emit key, obj

    ###
    # Listen to a specific event. If `onlyNewClients` is true then it won't listen to that particular
    # event from currently connected clients.
    # @param {String} key The event key.
    # @param {Function} callback The callback to be called when key is triggered.
    # @param {Boolean} onlyNewClients Optional, if true, listen to event only from new clients.
    ###
    listenTo: (key, callback, onlyNewClients) =>
        if not settings?.sockets.enabled
            return logger.notEnabled "Sockets"
        else if not @ready
            return

        onlyNewClients = false if not onlyNewClients?
        @currentListeners.push {key: key, callback: callback}

        logger.debug "Sockets.listenTo", key, callback, onlyNewClients

        if not onlyNewClients
            for key, socket of @io.sockets.connected
                socket.on key, callback

    ###
    # Stops listening to the specified event key.
    # @param {String} key The event key.
    # @param {Object} callback The callback to stop triggering.
    ###
    stopListening: (key, callback) =>
        if not settings?.sockets.enabled
            return logger.notEnabled "Sockets"
        else if not @ready
            return

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

    ###
    # Remove invalid and expired event listeners.
    ###
    compact: =>
        @currentListeners = lodash.compact @currentListeners

    # HELPERS
    # ----------------------------------------------------------------------

    ###
    # Get how many users are currenly connected to the app.
    # @return {Number} Number of active connections to the server.
    ###
    getConnectionCount: =>
        return 0 if not @ready or not @io?.sockets?
        return Object.keys(@io.sockets.connected).length

    ###
    # When user disconnects, emit an event with the new connection count to all clients.
    ###
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
