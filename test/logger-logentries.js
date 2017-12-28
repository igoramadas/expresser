// TEST: LOGGER LOGENTRIES

require("coffeescript/register")
var env = process.env
var chai = require("chai")
chai.should()

describe("Logger Logentries Tests", function() {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test"
    var hasEnv = env["LOGENTRIES_TOKEN"] ? true : false

    var settings = require("../lib/settings.coffee")
    var logger = null
    var loggerLogentries = null
    var transport = null

    var helperLogOnSuccess = function(done) {
        return function(result) {
            if (done.ran) return
            done.ran = true
            done()
        }
    }

    var helperLogOnError = function(done) {
        return function(err) {
            if (done.ran) return
            done.ran = true
            done(err)
        }
    }

    before(function() {
        settings.loadFromJson("../plugins/logger-logentries/settings.default.json")
        settings.loadFromJson("settings.test.json")

        if (env["LOGENTRIES_TOKEN"]) {
            settings.logger.logentries.token = env["LOGENTRIES_TOKEN"]
        }

        logger = require("../lib/logger.coffee").newInstance()

        loggerLogentries = require("../plugins/logger-logentries/index.coffee")
        loggerLogentries.expresser = require("../lib/index.coffee")
        loggerLogentries.expresser.events = require("../lib/events.coffee")
        loggerLogentries.expresser.logger = logger
    })

    it("Has settings defined", function() {
        settings.logger.should.have.property("logentries")
    })

    if (hasEnv) {
        it("Creates transport object", function() {
            logger.init()
            loggerLogentries.init()
            transport = logger.transports["logentries"]
        })

        it("Send log to Logentries", function(done) {
            this.timeout(10000)

            transport.client.on("log", helperLogOnSuccess(done))
            transport.client.on("error", helperLogOnError(done))

            transport.info("Expresser Logentries log test.", new Date())
        })
    } else {
        it.skip("Send log to Logentries (skipped, no token set)")
    }

    it("Fails to create transport with missing options", function(done) {
        try {
            var invalidTransport = loggerLogentries.getTransport()
            done("Calling getTransport(null) should throw an error.")
        } catch (ex) {
            done()
        }
    })
})
