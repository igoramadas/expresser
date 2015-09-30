// TEST: LOGGER

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Logger Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("../plugins/logger-file/settings.default.json");
    settings.loadFromJson("../plugins/logger-logentries/settings.default.json");
    settings.loadFromJson("../plugins/logger-loggly/settings.default.json");
    settings.loadFromJson("settings.test.json");

    if (env["logentries.token"]) {
        settings.logger.logentries.token = env["logentries.token"];
    }

    if (env["loggly.token"]) {
        settings.logger.loggly.token = env["loggly.token"];
    }

    if (env["loggly.subdomain"]) {
        settings.logger.loggly.subdomain = env["loggly.subdomain"];
    }

    var logger = null;
    var loggerFile = null;
    var loggerLogentries = null;
    var loggerLoggly = null;
    var transportFile = null;
    var transportLogentries = null;
    var transportLoggly = null;

    var helperLogOnSuccess = function(done) {
        return function(result) {
            done();
        };
    };

    var helperLogOnError = function(done) {
        return function(err) {
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
    });

    it("Save log to file", function(done) {
        transportFile = loggerFile.init({
            onLogSuccess: helperLogOnSuccess(done),
            onLogError: helperLogOnError(done)
        });

        transportFile.info("Expresser local disk log test.", new Date());
        transportFile.flush();
    });

    if (settings.logger.logentries.token) {
        it("Send log to Logentries", function(done) {
            this.timeout(10000);

            transportLogentries = loggerLogentries.init({
                onLogSuccess: helperLogOnSuccess(done),
                onLogError: helperLogOnError(done)
            });

            transportLogentries.info("Expresser Logentries log test.", new Date());
        });
    } else {
        it.skip("Send log to Logentries (skipped, no token set).");
    }

    if (settings.logger.logentries.token && settings.logger.loggly.subdomain) {
        it("Send log to Loggly", function(done) {
            this.timeout(10000);

            transportLoggly = loggerLoggly.init({
                onLogSuccess: helperLogOnSuccess(done),
                onLogError: helperLogOnError(done)
            });

            transportLoggly.info("Expresser Loggly log test.", new Date());
        });
    } else {
        it.skip("Send log to Loggly (skipped, no token or subdomain set).");
    }
});
