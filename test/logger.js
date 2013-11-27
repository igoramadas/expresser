// TEST: LOGGER

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Logger Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var utils = require("../lib/utils.coffee");
    var logger = null;
    var logentries_it = null;
    var loggly_it = null;

    utils.loadDefaultSettingsFromJson();

    // Check for LET (Logentries) and LOT (Loggly) variable on Travis.
    if (env.LET) {
        settings.logger.logentries.token = env.LET;
    }
    if (env.LOT) {
        settings.logger.loggly.token = env.LOT;
    }

    // Decide if Logentries should be tested.
    if (settings.logger.logentries.token && settings.logger.logentries.token != "") {
        logentries_it = it;
    } else {
        logentries_it = it.skip;
    }

    // Decide if Loggly should be tested.
    if (settings.logger.loggly.token && settings.logger.loggly.token != "") {
        loggly_it = it;
    } else {
        loggly_it = it.skip;
    }

    logger = require("../lib/logger.coffee");

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function(){
        utils.updateSettingsFromPaaS("logger");
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

    logentries_it("Send log to Logentries", function(done) {
        this.timeout(10000);

        settings.logger.loggly.enabled = false;
        settings.logger.local.enabled = false;
        settings.logger.logentries.enabled = true;

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

        logger.initLogentries();
        logger.info("Expresser Logentries test.", new Date());

        settings.logger.logentries.enabled = false;
    });

    loggly_it("Send log to Loggly", function(done) {
        this.timeout(10000);

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