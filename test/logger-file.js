// TEST: LOGGER FILE

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Logger File Tests", function () {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");


    if (env["LOGENTRIES_TOKEN"]) {
        settings.logger.logentries.token = env["LOGENTRIES_TOKEN"];
    }

    if (env["LOGGLY_TOKEN"]) {
        settings.logger.loggly.token = env["LOGGLY_TOKEN"];
    }

    if (env["LOGGLY_SUBDOMAIN"]) {
        settings.logger.loggly.subdomain = env["LOGGLY_SUBDOMAIN"];
    }

    var logger = null;
    var loggerFile = null;
    var transportFile = null;

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
        settings.loadFromJson("../plugins/logger-file/settings.default.json");
        settings.loadFromJson("settings.test.json");

        logger = require("../lib/logger.coffee");

        loggerFile = require("../plugins/logger-file/index.coffee");
        loggerFile.expresser = require("../index.coffee");
        loggerFile.expresser.events = require("../lib/events.coffee");
        loggerFile.expresser.logger = require("../lib/logger.coffee");
    });

    it("Has settings defined", function () {
        settings.logger.should.have.property("file");
    });

    it("Inits", function () {
        logger.init();
    });

    it("Save log to file", function (done) {
        transportFile = loggerFile.init({
            onLogSuccess: helperLogOnSuccess(done),
            onLogError: helperLogOnError(done)
        });

        transportFile.info("Expresser local disk log test.", {
            password: "obfuscated"
        }, new Date());
        transportFile.flush();
    });
});