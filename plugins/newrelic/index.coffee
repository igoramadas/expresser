# EXPRESSER FIREWALL
# -----------------------------------------------------------------------------
# Firewall to protect the server against well known HTTP and socket attacks.
# ATTENTION! The Firewall module is started automatically by the App module. If you wish to
# disable it, set `Settings.firewall.enabled` to false.
# <!--
# @see Settings.firewall
# -->
class NewRelic

    util = require "util"

    # INIT
    # -------------------------------------------------------------------------

    # Init New Relic.
    bind: (options, callback) =>
        enabled = settings.newRelic.enabled
        appName = process.env.NEW_RELIC_APP_NAME or settings.newRelic.appName
        licKey = process.env.NEW_RELIC_LICENSE_KEY or settings.newRelic.licenseKey

        # Check if New Relic settings are available, and if so, start the New Relic agent.
        if enabled and appName? and appName isnt "" and licKey? and licKey isnt ""
            targetFile = path.resolve path.dirname(require.main.filename), "newrelic.js"

            # Make sure the newrelic.js file exists on the app root, and create one if it doesn't.
            if not fs.existsSync targetFile
                if process.versions.node.indexOf(".10.") > 0
                    enc = {encoding: settings.general.encoding}
                else
                    enc = settings.general.encoding

                # Set values of newrelic.js file and write it to the app root.
                newRelicJson = "exports.config = {app_name: ['#{appName}'], license_key: '#{licKey}', logging: {level: 'trace'}};"
                fs.writeFileSync targetFile, newRelicJson, enc

                console.log "App", "Original newrelic.js file was copied to the app root, app_name and license_key were set."

            require "newrelic"
            console.log "App", "Started New Relic agent for #{appName}."

# Singleton implementation
# --------------------------------------------------------------------------
NewRelic.getInstance = ->
    @instance = new NewRelic() if not @instance?
    return @instance

module.exports = exports = NewRelic.getInstance()
