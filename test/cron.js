// TEST: CRON

require("coffee-script/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("Cron Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var events = require("../lib/events.coffee");
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
            basePath: "../../../lib/"
        });

        if (cron.jobs.length == 2) {
            done();
        } else {
            done("Cron should have two jobs loaded from testcron.json, but has " + cron.jobs.length + " jobs.");
        }
    });

    it("Exception when trying to load an invalid file", function (done) {
        if (cron.load("this-does-not/exist.json").notFound) {
            done();
        } else {
            done("Loading an invalid file should throw an exception, but it didn't.");
        }
    });

    it("Start loaded cron jobs", function (done) {
        this.timeout(10000);

        var verify = function (ok) {
            events.off("cron-seconds", verify);

            if (ok === 1) {
                done()
            } else {
                done("Event should emit 1, but we got " + ok);
            }
        };

        events.on("cron-seconds", verify);

        cron.start();
    });

    it("Remove cron-seconds job loaded from testcron.json", function (done) {
        var length = cron.jobs.length;
        cron.remove("cron-seconds");

        if (cron.jobs.length < length) {
            done();
        } else {
            done("Job cron-seconds was not removed from cron jobs list.");
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

    it("Throw error when adding invalid jobs", function (done) {
        var err = false;

        try {
            cron.add({
                missing_id: true
            });
            err = "Cron.add(missing id) should throw an error, but did not."
        } catch (ex) {}

        if (!err) {
            try {
                cron.add({
                    id: 123,
                    callback: "invalid"
                });
                err = "Cron.add(invalid callback) should throw an error, but did not."
            } catch (ex) {}
        }

        if (err) {
            done();
        } else {
            done(err);
        }
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

    it("Do not start cron jobs when module is not enabled", function (done) {
        settings.cron.enabled = false;

        if (!cron.load().notEnabled) {
            done("Cron.load should not run when settings.cron.enabled is false.")
        } else if (!cron.start().notEnabled) {
            done("Cron.start should not run when settings.cron.enabled is false.")
        } else {
            done();
        }
    });
});
