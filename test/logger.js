// TEST: LOGGER

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Logger Tests", function() {
    process.env.NODE_ENV = "test";

    var env = process.env;
    var envSettings = env.EXPRESSER_SETTINGS;
    var settings = require("../lib/settings.coffee");
    var utils = null;
    var logger = null;

    if (envSettings) {
        try {
            envSettings = JSON.parse(envSettings);
        } catch (ex) {
            envSettings = null;
            console.warn("Can't parse EXPRESSER_SETTINGS variable.");
        }
    }

    before(function() {
        utils = require("../lib/utils.coffee");
        utils.loadDefaultSettingsFromJson();

        logger = require("../lib/logger.coffee");

        try {
            if (envSettings) {
                if (!settings.logger.logentries.token) {
                    settings.logger.logentries.token = envSettings.logger.logentries.token;
                }

                if (!settings.logger.loggly.token) {
                    settings.logger.loggly.token = envSettings.logger.loggly.token;
                }

                if (!settings.logger.loggly.subdomain) {
                    settings.logger.loggly.subdomain = envSettings.logger.loggly.subdomain;
                }
            }
        } catch (ex) {
            console.warn("Can't load settings from EXPRESSER_SETTINGS variable");
        }
    });

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

    if (settings.logger.logentries.token) {
        it("Send info logline to Logentries.", function(done) {
            this.timeout(5000);

            settings.logger.loggly.enabled = false;
            settings.logger.local.enabled = false;
            settings.logger.logentries.enabled = true;

            logger.onLogSuccess = function(result) { console.log(result); done(); };
            logger.onLogError = function(err) { console.error(err); throw err };
            logger.initLogentries();
            logger.info("Expresser Logentries test.", new Date());

            settings.logger.logentries.enabled = false;
            logger.initLogentries();
        });
    } else {
        console.warn("Skipping Logentries test because token was not specified.");
    }

    if (settings.logger.loggly.token) {
        it("Send info logline to Loggly.", function(done) {
            this.timeout(5000);

            settings.logger.logentries.enabled = false;
            settings.logger.local.enabled = false;
            settings.logger.loggly.enabled = true;

            logger.onLogSuccess = function(result) { console.log(result); done(); };
            logger.onLogError = function(err) { console.error(err); throw err };
            logger.initLoggly();
            logger.info("Expresser Loggly test.", new Date());

            settings.logger.loggly.enabled = false;
            logger.initLoggly();
        });
    } else {
        console.warn("Skipping Loggly test because token was not specified.");
    }

    it("Clear onLogSuccess and onLogError.", function() {
        logger.onLogSuccess = null;
        logger.onLogError = null;
    });
});