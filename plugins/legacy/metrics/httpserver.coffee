# METRICS: HTTP SERVER HELPER
# --------------------------------------------------------------------------

###
# Helper class to manage the HTTP server exposing the metrics output.
###
class HttpServer

    metrics = null
    express = null
    logger = null
    settings = null
    webServer = null

    ##
    # Express server used to expose the reports via HTTP.
    # @property
    server: null

    ###
    # Init the HTTP server class.
    ###
    init: (parent) =>
        metrics = parent
        express = metrics.expresser.libs.express
        logger = metrics.expresser.logger
        settings = metrics.expresser.settings

        delete @init

    ###
    # Start the Express / HTTP server.
    ###
    start: ->
        logger.debug "Metrics.httpServer.start"

        if not settings.metrics.enabled
            return logger.notEnabled "Metrics"

        return false if webServer?

        try
            @server = express()
            @server.get settings.metrics.httpServer.path, (req, res) -> res.json metrics.output()
            webServer = @server.listen settings.metrics.httpServer.port
        catch ex
            logger.error "Metrics.httpServer.start", ex
            return {error: ex}

        logger.info "Metrics.httpServer.start", settings.metrics.httpServer.port
        return true

    ###
    # Kill the Express / HTTP server.
    ###
    kill: ->
        logger.debug "Metrics.httpServer.kill"

        return false if not webServer?

        try
            webServer.close()
            webServer = null
        catch ex
            logger.error "Metrics.httpServer.kill", ex
            return {error: ex}

        logger.info "Metrics.httpServer.kill"
        return true

# Singleton implementation
# -----------------------------------------------------------------------------
HttpServer.getInstance = ->
    @instance = new HttpServer() if not @instance?
    return @instance

module.exports = exports = HttpServer.getInstance()
