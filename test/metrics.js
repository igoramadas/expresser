// TEST: METRICS

require("coffeescript/register")
var env = process.env
var chai = require("chai")
chai.should()

describe("Metrics Tests", function() {
    env.NODE_ENV = "test"
    process.setMaxListeners(20)

    var settings = require("../lib/settings.coffee")
    var supertest = require("supertest")
    var metrics = null
    var totalCalls = 0

    before(function() {
        settings.loadFromJson("../plugins/metrics/settings.default.json")
        settings.loadFromJson("settings.test.json")

        metrics = require("../plugins/metrics/index.coffee")
        metrics.expresser = require("../lib/index.coffee")
        metrics.expresser.events = require("../lib/events.coffee")
        metrics.expresser.logger = require("../lib/logger.coffee")
    })

    it("Has settings defined", function() {
        settings.should.have.property("metrics")
    })

    it("Inits", function() {
        metrics.init()
    })

    it("Measure time to iterate randomly", function(done) {
        this.timeout(10000)

        var counter = 0
        var phrase = ""
        var mt, a, b

        for (i = 0; i < 100; i++) {
            mt = metrics.start("iteratorSum")
            totalCalls++

            for (b = 0; b < 100000; b++) {
                counter++
            }

            mt.setData("counter", i)
            mt.end()
        }

        for (i = 0; i < 100; i++) {
            mt = metrics.start("iteratorString")
            totalCalls++

            for (b = 0; b < 10000; b++) {
                phrase += "0"
            }

            metrics.end(mt)
        }

        done()
    })

    it("Expire metrics", function(done) {
        this.timeout(5000)

        var mt = metrics.start("expiredCall", 0, 100)

        var callback = function() {
            var output = metrics.output()
            var expired = output.expiredCall.last_1min.expired

            if (expired > 0) {
                done()
            } else {
                done("Output should have 1 expired metric for expiredCall, but has " + expired + ".")
            }
        }

        setTimeout(callback, 800)
    })

    it("Output has system metrics", function(done) {
        var output = metrics.output()

        if (!output.system || !output.system.loadAvg || !output.system.memoryUsage) {
            done("Metrics output expects server's loadAvg and memoryUsage.")
        } else {
            done()
        }
    })

    it("Output all the metrics gathered on tests", function(done) {
        var output = metrics.output()

        if (!output.iteratorSum || !output.iteratorString || output.iteratorSum.total_calls + output.iteratorString.total_calls != totalCalls) {
            done("Metrics output expects data for iteratorSum, iteratorString and total calls should be " + totalCalls + ".")
        } else {
            done()
        }
    })

    it("Output the metrics gathered on tests, but only for iteratorString", function(done) {
        var output = metrics.output({
            keys: ["iteratorString"]
        })

        if (!output.iteratorString || output.iteratorSum) {
            done("Output should have 'iteratorString' metrics only.")
        } else {
            done()
        }
    })

    it("Output iteratorSum has min / max data calculated", function(done) {
        var output = metrics.output()

        if (!output.iteratorSum.last_1min.data || !output.iteratorSum.last_1min.data.counter) {
            done("Metrics output has no 'data.counter' property calculated")
            return
        }

        var min = output.iteratorSum.last_1min.data.counter.min
        var max = output.iteratorSum.last_1min.data.counter.max

        if (min != 0 || max != 99) {
            done("Metrics output expects .data.counter min = 0 and max = 99, but got min " + min + " and max " + max + ".")
        } else {
            done()
        }
    })

    it("Start the dedicated HTTP server", function(done) {
        var started = metrics.httpServer.start()

        if (started.error) {
            done("Error starting the Metrics HTTP server: " + started.error)
        } else {
            done()
        }
    })

    it("Output via dedicated HTTP server", function(done) {
        supertest(metrics.httpServer.server)
            .get("/")
            .expect("Content-Type", /json/)
            .expect(200, done)
    })

    it("Kill the dedicated HTTP server", function(done) {
        var killed = metrics.httpServer.kill()

        if (killed.error) {
            done("Error killing the Metrics HTTP server: " + killed.error)
        } else {
            done()
        }
    })

    it("Metrics cleanup (expireAfter set to 0)", function(done) {
        settings.metrics.expireAfter = 0

        metrics.cleanup()
        count = metrics.get("iteratorSum").length

        if (count > 0) {
            done("Iterator metrics should have 0 data, but has " + count + ".")
        } else {
            done()
        }
    })
})
