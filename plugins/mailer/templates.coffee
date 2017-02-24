# MAILER TEMPLATES
# --------------------------------------------------------------------------
# Helper class to load and parse email templates.
class Templates

    fs = require "fs"
    path = require "path"
    settings = null

    cache: {}

    # Init the Templates class.
    init: (parent) =>
        settings = parent.settings

# Singleton implementation
# --------------------------------------------------------------------------
Templates.getInstance = ->
    @instance = new Templates() if not @instance?
    return @instance

module.exports = exports = Templates.getInstance()
