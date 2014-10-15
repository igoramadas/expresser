// TEST: LOGGER

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Logger Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    if (!settings.testKeysLoaded) {
        settings.loadFromJson("settings.test.keys.json");
        settings.testKeysLoaded = true;
    }

    var logger = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function(){
        logger = require("../lib/logger.coffee");
    });

    it("Is single instance", function() {
        logger.singleInstance = true;
        var logger2 = require("../lib/logger.coffee");
        logger.singleInstance.should.equal(logger2.singleInstance);
    });

    it("Has settings defined", function() {
        settings.should.have.property("logger");
    });

    it("Inits", function() {
        logger.init();
    });

    it("Save log to local file", function(done) {
        var isDone = false;

        settings.logger.loggly.enabled = false;
        settings.logger.logentries.enabled = false;
        settings.logger.local.enabled = true;

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

        logger.initLocal();
        logger.info("Expresser local disk log test.", new Date());
        logger.flushLocal();

        settings.logger.local.enabled = false;
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
