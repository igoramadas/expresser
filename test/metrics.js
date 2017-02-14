// TEST: METRICS

require("coffee-script/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("Metrics Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var metrics = null;
    var totalCalls = 0;

    before(function () {
        settings.loadFromJson("../plugins/metrics/settings.default.json");
        settings.loadFromJson("settings.test.json");

        metrics = require("../plugins/metrics/index.coffee");
        metrics.expresser = require("../index.coffee");
        metrics.expresser.events = require("../lib/events.coffee");
        metrics.expresser.logger = require("../lib/logger.coffee");
    });

    it("Has settings defined", function () {
        settings.should.have.property("metrics");
    });

    it("Inits", function () {
        metrics.init();
    });

    it("Measure time to iterate from 0 to 10k, 100 times", function (done) {
        this.timeout(10000);

        var counter = 0;
        var mt, a, b;

        for (i = 0; i < 100; i++) {
            mt = metrics.start("iterator", counter);
            totalCalls++;

            for (b = 0; b < 10000; b++) {
                counter++;
            }

            metrics.end(mt, null);
        }

        done();
    });

    it("Output the metrics gathered on tests", function (done) {
        var output = metrics.output();

        if (!output.iterator) {
            done("Could not find 'iterator' metrics on the output.")
        } else if (output.iterator.total_calls != totalCalls) {
            done("Was expecting " + totalCalls + " total calls, but got " + output.iterator.total_calls + ".")
        } else {
            done();
        }
    });

    it("Metrics cleanup (expireAfter set to 0)", function (done) {
        settings.metrics.expireAfter = 0;

        metrics.cleanup();
        count = metrics.get("iterator").length;

        if (count > 0) {
            done("Iterator metrics should have 0 data, but has " + count + ".")
        } else {
            done();
        }
    });
});
