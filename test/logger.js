// TEST: LOGGER

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Logger Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var utils = null;
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
        settings.logger.loggly.enabled = false;
        settings.logger.logentries.enabled = false;
        settings.logger.local.enabled = true;

        logger.onLogSuccess = function(result) {
            logger.onLogSuccess = null;
            logger.onLogError = null;
            done();
        };

        logger.onLogError = function(err) {
            logger.onLogSuccess = null;
            logger.onLogError = null;
            done(err);
        };

        logger.initLocal();
        logger.info("Expresser local disk log test.", new Date());
        logger.flushLocal();

        settings.logger.local.enabled = false;
    });

    it("Send log to Logentries", function(done) {
        this.timeout(10000);

        if (!env.LET) {
            return done(new Error("The 'LET' variable which defines the Logentries token was not set."));
        }

        settings.logger.logentries.token = env.LET;
        settings.logger.loggly.enabled = false;
        settings.logger.local.enabled = false;
        settings.logger.logentries.enabled = true;

        logger.onLogSuccess = function() {
            logger.onLogSuccess = null;
            logger.onLogError = null;
            done();
        };

        logger.onLogError = function(err) {
            logger.onLogSuccess = null;
            logger.onLogError = null;
            done(err);
        };

        logger.initLogentries();
        logger.info("Expresser Logentries test.", new Date());

        settings.logger.logentries.enabled = false;
    });

    it("Send log to Loggly", function(done) {
        this.timeout(10000);

        if (!env.LOT) {
            return done(new Error("The 'LOT' variable which defines the Loggly token was not set."));
        }

        settings.logger.loggly.token = env.LOT;
        settings.logger.logentries.enabled = false;
        settings.logger.local.enabled = false;
        settings.logger.loggly.enabled = true;

        logger.onLogSuccess = function(result) {
            logger.onLogSuccess = null;
            logger.onLogError = null;
            done();
        };

        logger.onLogError = function(err) {
            logger.onLogSuccess = null;
            logger.onLogError = null;
            done(err);
        };

        logger.initLoggly();
        logger.info("Expresser Loggly test.", new Date());

        settings.logger.loggly.enabled = false;
    });
});