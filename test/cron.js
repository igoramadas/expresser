// TEST: CRON

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Cron Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    if (!settings.testKeysLoaded) {
        settings.loadFromJson("settings.test.keys.json");
        settings.testKeysLoaded = true;
    }

    var utils = null;
    var cron = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        utils = require("../lib/utils.coffee");
        cron = require("../plugins/cron/index.coffee");
        cron.expresser = require("../index.coffee");
        cron.expresser.events = require("../lib/events.coffee");
        cron.expresser.logger = require("../lib/logger.coffee");
    });

    it("Has settings defined", function() {
        settings.should.have.property("cron");
    });

    it("Add and run a cron job, passing itself to the callback", function(done) {
        var schedule = 1;
        var callback = function(jobRef) {
            if (jobRef.schedule == schedule)
            {
                done();
            }
            else
            {
                done("The job was not passed to the callback.")
            }
        };

        var job = {id: "testjob", callback: callback, schedule: schedule, once: true};

        cron.add(job);
    });

    it("Prevents duplicate jobs when 'allowReplacing' setting is false", function(done) {
        var callback = function() { return true; };
        var job1 = {id: "uniqueJob", callback: callback, schedule: 1000, once: true};
        var job2 = {id: "uniqueJob", callback: callback, schedule: 2000, once: false};

        settings.cron.allowReplacing = false;

        cron.add(job1);

        if (cron.add(job2).error) {
            done();
        } else {
            done("Duplicate job was added, and it shouldn't be.")
        }
    });
});
