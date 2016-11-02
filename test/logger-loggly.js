// TEST: LOGGER LOGGLY

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Logger Loggly Tests", function () {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");


    var logger = null;
    var loggerLoggly = null;
    var transportLoggly = null;

    var helperLogOnSuccess = function (done) {
        return function (result) {
            done();
        };
    };

    var helperLogOnError = function (done) {
        return function (err) {
            done(err);
        };
    };

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function () {
        var env = process.env;

        settings.loadFromJson("../plugins/logger-loggly/settings.default.json");
        settings.loadFromJson("settings.test.json");

        if (env["LOGGLY_TOKEN"]) {
            settings.logger.loggly.token = env["LOGGLY_TOKEN"];
        }

        if (env["LOGGLY_SUBDOMAIN"]) {
            settings.logger.loggly.subdomain = env["LOGGLY_SUBDOMAIN"];
        }

        logger = require("../lib/logger.coffee");

        loggerLoggly = require("../plugins/logger-loggly/index.coffee");
        loggerLoggly.expresser = require("../index.coffee");
        loggerLoggly.expresser.events = require("../lib/events.coffee");
        loggerLoggly.expresser.logger = require("../lib/logger.coffee");
    });

    it("Has settings defined", function () {
        settings.logger.should.have.property("loggly");
    });

    if (settings.logger.loggly && settings.logger.loggly.token && settings.logger.loggly.subdomain) {
        it("Creates transport object", function () {
            logger.init();

            transportLoggly = loggerLoggly.init();
        });

        it("Send log to Loggly", function (done) {
            this.timeout(10000);

            transportLoggly.onLogSuccess = helperLogOnSuccess(done);
            transportLoggly.onLogError = helperLogOnError(done);

            transportLoggly.info("Expresser Loggly log test.", new Date());
        });
    } else {
        it.skip("Send log to Loggly (skipped, no token or subdomain set)");
    }
});