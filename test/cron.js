// TEST: CRON

require("coffee-script/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("Cron Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var utils = null;
    var cron = null;

    before(function () {
        settings.loadFromJson("../plugins/cron/settings.default.json");
        settings.loadFromJson("settings.test.json");

        utils = require("../lib/utils.coffee");

        cron = require("../plugins/cron/index.coffee");
        cron.expresser = require("../index.coffee");
        cron.expresser.events = require("../lib/events.coffee");
        cron.expresser.logger = require("../lib/logger.coffee");
    });

    it("Has settings defined", function () {
        settings.should.have.property("cron");
    });

    it("Inits", function () {
        cron.init();
    });

    it("Loads jobs from a testcron.json file", function (done) {
        cron.load("test/testcron.json", {
            autoStart: false,
            basePath: "../../../"
        });

        if (cron.jobs.length == 1) {
            done();
        } else {
            done("Cron should have a single job loaded from testcron.json, but has " + cron.jobs.length + " jobs.");
        }
    });

    it("Remove test123 job loaded from testcron.json", function (done) {
        var length = cron.jobs.length;
        cron.remove("test123");

        if (cron.jobs.length < length) {
            done();
        } else {
            done("Job test123 was not removed from cron jobs list.");
        }
    });

    it("Add and run a cron job, passing itself to the callback", function (done) {
        var schedule = 1;
        var callback = function (jobRef) {
            if (jobRef.schedule == schedule) {
                done();
            } else {
                done("The job was not passed to the callback.")
            }
        };

        var job = {
            id: "testjob",
            callback: callback,
            schedule: schedule,
            once: true
        };

        cron.add(job);
    });

    it("Stop jobs", function (done) {
        cron.stop();

        for (var j = 0; j < cron.jobs.length; j++) {
            if (cron.jobs[j].timer != null) {
                return done("Cron still has jobs enabled after calling stop().");
            }
        }

        done();
    });

    it("Prevents duplicate jobs when 'allowReplacing' setting is false", function (done) {
        var callback = function () {
            return true;
        };
        var job1 = {
            id: "uniqueJob",
            callback: callback,
            schedule: 1000,
            once: true
        };
        var job2 = {
            id: "uniqueJob",
            callback: callback,
            schedule: 2000,
            once: false
        };

        settings.cron.allowReplacing = false;

        cron.add(job1);

        if (cron.add(job2).error) {
            done();
        } else {
            done("Duplicate job was added, and it shouldn't be.")
        }
    });
});