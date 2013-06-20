// TEST: LOGGER

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Logger Tests", function() {

    var logger = require("../lib/logger.coffee");
    var settings = require("../lib/settings.coffee");
    var env = process.env;

    it("Is single instance.", function() {
        logger.singleInstance = true;
        var logger2 = require("../lib/logger.coffee");
        logger.singleInstance.should.equal(logger2.singleInstance);
    });

    it("Has settings defined.", function() {
        settings.should.have.property("logger");
    });

    it("Inits.", function() {
        logger.init();
    });

    it("Send info logline to Logentries.", function(done) {
        this.timeout(10000);

        settings.logger.logentries.enabled = true;
        settings.logger.logentries.token = env.LOGENTRIES_TOKEN;

        logger.onLogSuccess = function(result) { console.log(result); done(); };
        logger.onLogError = function(err) { console.error(err); throw err };
        logger.initLogentries();
        logger.info("Expresser Logentries test.", new Date());

        settings.logger.logentries.enabled = false;
        logger.initLogentries();
    });

    it("Send info logline to Loggly.", function(done) {
        this.timeout(10000);

        settings.logger.loggly.enabled = true;
        settings.logger.loggly.token = env.LOGGLY_TOKEN;
        settings.logger.loggly.subdomain = env.LOGGLY_SUBDOMAIN;

        logger.onLogSuccess = function(result) { console.log(result); done(); };
        logger.onLogError = function(err) { console.error(err); throw err };
        logger.initLoggly();
        logger.info("Expresser Loggly test.", new Date());

        settings.logger.loggly.enabled = false;
        logger.initLoggly();
    });

    it("Clear onLogSuccess and onLogError.", function() {
        logger.onLogSuccess = null;
        logger.onLogError = null;
    });
});