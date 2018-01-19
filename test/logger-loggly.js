// TEST: LOGGER LOGGLY

require("coffeescript/register")
var env = process.env
var chai = require("chai")
chai.should()

describe("Logger Loggly Tests", function() {
    env.NODE_ENV = "test"
    process.setMaxListeners(20)

    var hasEnv = env["LOGGLY_TOKEN"] ? true : false

    var settings = require("../lib/settings.coffee")
    var logger = null
    var loggerLoggly = null
    var transport = null

    var helperLogOnSuccess = function(done) {
        return function(result) {
            if (done.ran) return
            done.ran = true
            done()
        }
    }

    var helperLogOnError = function(done, ex) {
        return function(err) {
            if (done.ran) return
            if (!err) err = ex
            done.ran = true
            done(err)
        }
    }

    before(function() {
        settings.loadFromJson("../plugins/logger-loggly/settings.default.json")
        settings.loadFromJson("settings.test.json")

        if (env["LOGGLY_TOKEN"]) {
            settings.logger.loggly.token = env["LOGGLY_TOKEN"]
        }

        if (env["LOGGLY_SUBDOMAIN"]) {
            settings.logger.loggly.subdomain = env["LOGGLY_SUBDOMAIN"]
        }

        logger = require("../lib/logger.coffee").newInstance()

        loggerLoggly = require("../plugins/logger-loggly/index.coffee")
        loggerLoggly.expresser = require("../lib/index.coffee")
        loggerLoggly.expresser.events = require("../lib/events.coffee")
        loggerLoggly.expresser.logger = logger
    })

    after(function() {
        if (transport) {
            transport.onLogSuccess = null
            transport.onLogError = null
        }
    })

    it("Has settings defined", function() {
        settings.logger.should.have.property("loggly")
    })

    if (hasEnv) {
        it("Creates transport object", function() {
            logger.init()
            loggerLoggly.init()
            transport = logger.transports["loggly"]
        })

        it("Send log to Loggly", function(done) {
            this.timeout(10000)

            try {
                transport.onLogSuccess = helperLogOnSuccess(done)
                transport.onLogError = helperLogOnError(done)

                transport.info("Expresser Loggly log test.", new Date())
            } catch (ex) {
                helperLogOnError(done, ex)
            }
        })
    } else {
        it.skip("Send log to Loggly (skipped, no token or subdomain set)")
    }

    it("Fails to create transport with missing options", function(done) {
        try {
            var invalidTransport = loggerLoggly.getTransport()
            done("Calling getTransport(null) should throw an error.")
        } catch (ex) {
            done()
        }
    })
})
