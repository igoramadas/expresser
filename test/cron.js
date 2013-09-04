// TEST: CRON

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Cron Tests", function() {
    process.env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var utils = null;
    var cron = null;

    before(function() {
        utils = require("../lib/utils.coffee");
        utils.loadDefaultSettingsFromJson();

        cron = require("../lib/cron.coffee");
    });

    it("Is single instance", function() {
        cron.singleInstance = true;
        var cron2 = require("../lib/cron.coffee");
        cron.singleInstance.should.equal(cron2.singleInstance);
    });

    it("Has settings defined", function() {
        settings.should.have.property("cron");
    });

    it("Add and run a cron job, passing itself to the callback", function(done) {
        var schedule = 990;
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

        var job = {callback: callback, schedule: schedule};

        cron.add("testAddJob", job);
    });
});