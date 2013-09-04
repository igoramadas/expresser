// TEST: CRON

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Cron Tests", function() {
    process.env.NODE_ENV = "test";

    var env = process.env;
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

    it("Add and run a cron job", function(done) {
        var callback = function(jobRef) {
            console.warn("JOB RERERENCE!!!");
            console.warn(jobRef);
            done();
        };

        var job = {callback: callback, schedule: 1000};

        cron.add("test", job);
    });
});