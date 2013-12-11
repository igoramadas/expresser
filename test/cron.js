// TEST: CRON

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Cron Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var cron = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
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

        var job = {callback: callback, schedule: schedule, once: true};

        cron.add("testAddJob", job);
    });
});