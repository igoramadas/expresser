// TEST: LOGGER LOGENTRIES

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Logger Logentries Tests", function () {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var logger = null;
    var loggerLogentries = null;
    var transportLogentries = null;

    var helperLogOnSuccess = function (done) {
        if (done.ran) return;
        done.ran = true;

        return function (result) {
            done();
        };
    };

    var helperLogOnError = function (done) {
        if (done.ran) return;
        done.ran = true;

        return function (err) {
            done(err);
        };
    };

    before(function () {
        var env = process.env;

        settings.loadFromJson("../plugins/logger-logentries/settings.default.json");
        settings.loadFromJson("settings.test.json");

        if (env["LOGENTRIES_TOKEN"]) {
            settings.logger.logentries.token = env["LOGENTRIES_TOKEN"];
        }

        logger = require("../lib/logger.coffee");

        loggerLogentries = require("../plugins/logger-logentries/index.coffee");
        loggerLogentries.expresser = require("../index.coffee");
        loggerLogentries.expresser.events = require("../lib/events.coffee");
        loggerLogentries.expresser.logger = require("../lib/logger.coffee");
    });

    it("Has settings defined", function () {
        settings.logger.should.have.property("logentries");
    });

    if (settings.logger.logentries && settings.logger.logentries.token) {
        it("Creates transport object", function () {
            logger.init();

            transportLogentries = loggerLogentries.init();
        });

        it("Send log to Logentries", function (done) {
            this.timeout(10000);

            transportLogentries.onLogSuccess = helperLogOnSuccess(done);
            transportLogentries.onLogError = helperLogOnError(done);

            transportLogentries.info("Expresser Logentries log test.", new Date());
        });
    } else {
        it.skip("Send log to Logentries (skipped, no token set)");
    }
});