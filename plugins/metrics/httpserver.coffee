# HTTP SERVER HELPER
# --------------------------------------------------------------------------
# Helper class to manage the HTTP server exposing the metrics output.
class HttpServer

    server:

    start: =>

    kill: =>

# Singleton implementation.
# -----------------------------------------------------------------------------
HttpServer.getInstance = ->
    @instance = new HttpServer() if not @instance?
    return @instance

module.exports = exports = HttpServer.getInstance()
