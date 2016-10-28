// TEST: LOGGER

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Logger Tests", function () {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("../plugins/logger-file/settings.default.json");
    settings.loadFromJson("../plugins/logger-logentries/settings.default.json");
    settings.loadFromJson("../plugins/logger-loggly/settings.default.json");
    settings.loadFromJson("settings.test.json");

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
    var loggerLogentries = null;
    var loggerLoggly = null;
    var transportFile = null;
    var transportLogentries = null;
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

    it("Has settings defined", function () {
        settings.should.have.property("logger");
        settings.logger.should.have.property("file");
        settings.logger.should.have.property("logentries");
        settings.logger.should.have.property("loggly");
    });

    it("Inits", function () {
        logger.init();
    });

    it("Logs on diffent levels (debug, info, warn, error, critical)", function () {
        logger.debug("THIS IS DEBUG");
        logger.info("THIS IS INFO");
        logger.warn("THIS IS WARN");
        logger.error("THIS IS ERROR");
        logger.critical("THIS IS CRITICAL");
    });

    it("Clean arguments before logging", function (done) {
        var testObj = {
            someFunction: function () {
                return true
            },
            password: "this should be obfuscated.",
            level0: {
                level1: {
                    level2: {
                        level3: {
                            level4: {
                                level5: {
                                    level6: {
                                        level7: {
                                            level8: {
                                                level9: true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        };

        var simpleObj = "This is a string";
        var cleanArgs = logger.argsCleaner(testObj, simpleObj);

        if (cleanArgs[0].password == testObj.password) {
            done("Password on test object was not obfuscated.");
        } else if (cleanArgs[0].level0.level1.level2.level3.level4.level5.level6.level7.level8.level9) {
            done("Maximum deep level should be 8, but test object has a property with 9 levels down.");
        } else {
            done();
        }
    });

    it("Get a stringfied message out of the arguments", function (done) {
        var time = new Date().getTime();
        var message = logger.getMessage(1, "A", time).toString();

        if (message.indexOf(1) < 0 || message.indexOf("A") < 0) {
            done("Stringified message should have values 1 and A on.");
        } else {
            done();
        }
    });

    it("Check if removed fields are hidden from log", function (done) {
        var privateObj = {
            password: "Welcome123",
            username: "jondoe",
            comments: "This should appear on log",
            deep: {
                auth: {
                    credentials: "lalala"
                }
            }
        };

        var someMessage = "Some more stuff here.";
        var cleanMessage = logger.getMessage([privateObj, someMessage]);
        var loggedMessage = JSON.stringify(logger.console("info", cleanMessage));

        if (loggedMessage.indexOf("Welcome123") > 0 || loggedMessage.indexOf("lalala") > 0) {
            done("Fields were not hidden from log message.");
        } else {
            done();
        }
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

    if (settings.logger.logentries.token) {
        it("Send log to Logentries", function (done) {
            this.timeout(10000);

            transportLogentries = loggerLogentries.init({
                onLogSuccess: helperLogOnSuccess(done),
                onLogError: helperLogOnError(done)
            });

            transportLogentries.info("Expresser Logentries log test.", new Date());
        });
    } else {
        it.skip("Send log to Logentries (skipped, no token set)");
    }

    if (settings.logger.logentries.token && settings.logger.loggly.subdomain) {
        it("Send log to Loggly", function (done) {
            this.timeout(10000);

            transportLoggly = loggerLoggly.init({
                onLogSuccess: helperLogOnSuccess(done),
                onLogError: helperLogOnError(done)
            });

            transportLoggly.info("Expresser Loggly log test.", new Date());
        });
    } else {
        it.skip("Send log to Loggly (skipped, no token or subdomain set)");
    }

    it("Registers a dummy log driver", function () {
        var driver = {
            getTransport: function () {
                return {};
            },
            log: function (data) {
                console.log("DUMMY DRIVER", data);
            }
        };

        logger.drivers["dummydriver"] = driver;
        logger.register("testlogger", "dummydriver");
    });
});