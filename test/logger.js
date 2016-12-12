// TEST: LOGGER

require("coffee-script/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("Logger Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var logger = null;

    before(function () {
        settings.loadFromJson("settings.test.json");

        logger = require("../lib/logger.coffee").newInstance();
    });

    it("Has settings defined", function () {
        settings.should.have.property("logger");
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

    it("Try to register invalid log driver", function () {
        if (!logger.register("invalid", "invalid")) {
            done();
        } else {
            done("Logger.register(invalid) should log an error and return false, but it didn't.")
        }
    });
});