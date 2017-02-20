# HTTP SERVER HELPER
# --------------------------------------------------------------------------
# Helper class to manage the HTTP server exposing the metrics output.
class HttpServer

    metrics = null
    express = null
    settings = null
    webServer = null

    # Express server is exposed to other modules.
    server: null

    # Init the HTTP server class.
    init: (parent) =>
        metrics = parent
        express = metrics.expresser.libs.express
        settings = metrics.expresser.settings

    # Start the server.
    start: =>
        return logger.notEnabled "Metrics", "start" if not settings.metrics.enabled
        return if webServer?

        @server = express()
        @server.get settings.metrics.httpServer.path, (req, res) -> res.json metrics.output()

        webServer = @server.listen settings.metrics.httpServer.port

    # Kill the server.
    kill: =>
        return logger.notEnabled "Metrics", "start" if not settings.metrics.enabled
        return if not webServer?

        webServer.close()
        webServer = null

# Singleton implementation.
# -----------------------------------------------------------------------------
HttpServer.getInstance = ->
    @instance = new HttpServer() if not @instance?
    return @instance

module.exports = exports = HttpServer.getInstance()
