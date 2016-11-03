// TEST: LOGGER FILE

require("coffee-script/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("Logger File Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
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

    before(function () {
        settings.loadFromJson("../plugins/logger-file/settings.default.json");
        settings.loadFromJson("settings.test.json");

        logger = require("../lib/logger.coffee").newInstance();

        loggerFile = require("../plugins/logger-file/index.coffee");
        loggerFile.expresser = require("../index.coffee");
        loggerFile.expresser.events = require("../lib/events.coffee");
        loggerFile.expresser.logger = logger;
    });

    it("Has settings defined", function () {
        settings.logger.should.have.property("file");
    });

    it("Creates transport object", function () {
        logger.init();
        transportFile = loggerFile.init();
    });

    it("Save log to file", function (done) {
        transportFile.onLogSuccess = helperLogOnSuccess(done);
        transportFile.onLogError = helperLogOnError(done);

        transportFile.info("Expresser local disk log test.", {
            password: "obfuscated",
            something: "hello!"
        }, new Date());

        transportFile.flush();
    });
});