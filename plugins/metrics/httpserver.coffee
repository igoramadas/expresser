# HTTP SERVER HELPER
# --------------------------------------------------------------------------
# Helper class to manage the HTTP server exposing the metrics output.
class HttpServer

    http = require "http"
    express = null
    settings = null
    server = null

    # Init the HTTP server class.
    init: (s, e) =>
        settings = s
        express = e

    # Start the server.
    start: =>
        return if server?

        server = http.createServer express()
        server.listen settings.metrics.httpServer.port

    # Kill the server.
    kill: =>
        return if not server?

        server.close()

# Singleton implementation.
# -----------------------------------------------------------------------------
HttpServer.getInstance = ->
    @instance = new HttpServer() if not @instance?
    return @instance

module.exports = exports = HttpServer.getInstance()
