// TEST: LOGGER

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Logger Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("settings.test.json");
    settings.loadFromJson("settings.test.keys.json");
    settings.loadFromJson("../plugins/logger-file/settings.default.json");
    settings.loadFromJson("../plugins/logger-logentries/settings.default.json");
    settings.loadFromJson("../plugins/logger-loggly/settings.default.json");

    var logger = null;
    var loggerFile = null;
    var loggerLogentries = null;
    var loggerLoggly = null;
    var transportFile = null;
    var transportLogentries = null;
    var transportLoggly = null;

    var helperLogOnSuccess = function(transport, done) {
        return function(result) {
            transport.expresser.logger.onLogSuccess = null;
            transport.expresser.logger.onLogError = null;
            done();
        };
    };

    var helperLogOnError = function(transport, done) {
        return function(err) {
            transport.expresser.logger.onLogSuccess = null;
            transport.expresser.logger.onLogError = null;
            done(err);
        };
    };

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function(){
        logger = require("../lib/logger.coffee");

        loggerFile = require("../plugins/logger-file/index.coffee");
        loggerFile.expresser = require("../index.coffee");
        loggerFile.expresser.events = require("../lib/events.coffee");
        loggerFile.expresser.logger = require("../lib/logger.coffee");

        loggerLogentries = require("../plugins/logger-logentries/index.coffee");
        loggerLogentries.expresser = require("../index.coffee");
        loggerLogentries.expresser.events = require("../lib/events.coffee");
        loggerLogentries.expresser.logger = require("../lib/logger.coffee");

        loggerLoggly = require("../plugins/logger-loggly/index.coffee");
        loggerLoggly.expresser = require("../index.coffee");
        loggerLoggly.expresser.events = require("../lib/events.coffee");
        loggerLoggly.expresser.logger = require("../lib/logger.coffee");
    });

    it("Has settings defined", function() {
        settings.should.have.property("logger");
        settings.logger.should.have.property("file");
        settings.logger.should.have.property("logentries");
        settings.logger.should.have.property("loggly");
    });

    it("Inits", function() {
        logger.init();

        transportFile = loggerFile.init();
        transportLogentries = loggerLogentries.init();
        transportLoggly = loggerLoggly.init();
    });

    it("Save log to file", function(done) {
        loggerFile.expresser.logger.onLogSuccess = helperLogOnSuccess(loggerFile, done);
        loggerFile.expresser.logger.onLogError = helperLogOnError(loggerFile, done);

        transportFile.info("Expresser local disk log test.", new Date());
        transportFile.flush();
    });

    it("Send log to Logentries", function(done) {
        var isDone = false;

        this.timeout(10000);

        if (!settings.logger.logentries.token) {
            return done(new Error("The Logentries token was not set (settings.logger.logentries.token)."));
        }

        settings.logger.loggly.enabled = false;
        settings.logger.local.enabled = false;
        settings.logger.logentries.enabled = true;

        logger.onLogSuccess = function() {
            logger.onLogSuccess = null;
            logger.onLogError = null;
            if (!isDone) done();
        };

        logger.onLogError = function(err) {
            logger.onLogSuccess = null;
            logger.onLogError = null;
            if (!isDone) done(err);
        };

        logger.initLogentries();
        logger.info("Expresser Logentries test.", new Date());

        settings.logger.logentries.enabled = false;
    });

    it("Send log to Loggly", function(done) {
        var isDone = false;

        this.timeout(10000);

        if (!settings.logger.loggly.token) {
            return done(new Error("The Logentries token was not set (settings.logger.loggly.token)."));
        }

        settings.logger.logentries.enabled = false;
        settings.logger.local.enabled = false;
        settings.logger.loggly.enabled = true;

        logger.onLogSuccess = function(result) {
            logger.onLogSuccess = null;
            logger.onLogError = null;
            if (!isDone) done();
        };

        logger.onLogError = function(err) {
            logger.onLogSuccess = null;
            logger.onLogError = null;
            if (!isDone) done(err);
        };

        logger.initLoggly();
        logger.info("Expresser Loggly test.", new Date());

        settings.logger.loggly.enabled = false;
    });
});
