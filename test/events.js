// TEST: EVENTS

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Cron Tests", function () {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("settings.test.json");

    var events = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function () {
        events = require("../lib/events.coffee");
    });

    it("Emit a test event", function (done) {
        var listener = function (someString) {
            if (someString == "test123") {
                done();
            } else {
                done("The value passed should be 'test123', and we've got '" + someString + "'.");
            }
        };

        events.on("Test.addListener", listener);
        events.emit("Test.addListener", "test123");
    });

    it("Add and remove a listener", function (done) {
        var listener = function () {
            done("Listener was not removed.");
        };

        events.on("Test.addListener", listener);
        events.off("Test.addListener", listener);
        events.emit("Test.addListener", true);

        var timer = function () {
            done();
        };

        setTimeout(timer, 500);
    });
});