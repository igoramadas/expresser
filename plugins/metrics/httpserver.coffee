# METRICS: HTTP SERVER HELPER
# --------------------------------------------------------------------------
# Helper class to manage the HTTP server exposing the metrics output.
class HttpServer

    metrics = null
    express = null
    logger = null
    settings = null
    webServer = null

    # Express server is exposed to other modules.
    server: null

    # Init the HTTP server class.
    init: (parent) ->
        metrics = parent
        express = metrics.expresser.libs.express
        logger = metrics.expresser.logger
        settings = metrics.expresser.settings

    # Start the server.
    start: ->
        logger.debug "Metrics.httpServer.start"

        if not settings.metrics.enabled
            return logger.notEnabled "Metrics"

        return if webServer?

        @server = express()
        @server.get settings.metrics.httpServer.path, (req, res) -> res.json metrics.output()

        try
            webServer = @server.listen settings.metrics.httpServer.port
        catch ex
            logger.error "Metrics.httpServer.start", ex
            return {error: ex}

        logger.info "Metrics.httpServer.start", settings.metrics.httpServer.port

    # Kill the server.
    kill: ->
        logger.debug "Metrics.httpServer.kill"

        return if not webServer?

        try
            webServer.close()
            webServer = null
        catch ex
            logger.error "Metrics.httpServer.kill", ex
            return {error: ex}

        logger.info "Metrics.httpServer.kill"

# Singleton implementation
# -----------------------------------------------------------------------------
HttpServer.getInstance = ->
    @instance = new HttpServer() if not @instance?
    return @instance

module.exports = exports = HttpServer.getInstance()
