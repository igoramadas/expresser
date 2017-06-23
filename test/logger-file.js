// TEST: LOGGER FILE

require("coffeescript/register");
var env = process.env;
var chai = require("chai");
var fs = require("fs");
chai.should();

describe("Logger File Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var events = require("../lib/events.coffee");
    var logger = null;
    var loggerFile = null;
    var transport = null;
    var logSaved = false;

    var helperLogOnSuccess = function () {
        return function (result) {
            logSaved = true;
        };
    };

    var helperLogOnError = function (done) {
        return function (err) {
            done(err);
        };
    };

    var deleteLogsFolder = function () {
        if (fs.existsSync(settings.logger.file.path)) {
            var files = fs.readdirSync(settings.logger.file.path);
            var f;

            for (f = 0; f < files.length; f++) {
                fs.unlinkSync(settings.logger.file.path + files[f]);
            }

            fs.rmdirSync(settings.logger.file.path);
        }
    };

    before(function () {
        settings.loadFromJson("../plugins/logger-file/settings.default.json");
        settings.loadFromJson("settings.test.json");
        settings.logger.file.path = __dirname + "/logs/";

        logger = require("../lib/logger.coffee").newInstance();

        loggerFile = require("../plugins/logger-file/index.coffee");
        loggerFile.expresser = require("../index.coffee");
        loggerFile.expresser.events = require("../lib/events.coffee");
        loggerFile.expresser.logger = logger;

        deleteLogsFolder();
    });

    after(function () {
        deleteLogsFolder();
    });

    it("Has settings defined", function () {
        settings.logger.should.have.property("file");
    });

    it("Creates transport object", function () {
        logger.init();
        transport = loggerFile.init();
    });

    it("Save log to file", function (done) {
        var onFlush = function () {
            if (logSaved) {
                done();
            } else {
                done("Log was not saved successfully");
            }
        };

        events.on("LoggerFile.on.flush", onFlush);

        transport.onLogSuccess = helperLogOnSuccess();
        transport.onLogError = helperLogOnError(done);

        transport.info("Expresser local disk log test.", {
            password: "obfuscated",
            something: "hello!"
        }, new Date());

        transport.flush();
    });

    it("Cleans all log files", function (done) {
        this.timeout(10000);

        transport.clean(0);

        var files;
        var counter = 0;

        var checkFiles = function () {
            counter++;
            files = fs.readdirSync(settings.logger.file.path);

            if (counter > 4) {
                done("Log folder should be empty after clearing, but has " + files.length + " files.");
            } else if (files.length > 0) {
                setTimeout(checkFiles, 1000);
            } else {
                done();
            }
        };

        setTimeout(checkFiles, 2000);
    });

    it("Fails to create transport with missing options", function (done) {
        try {
            var invalidTransport = loggerFile.getTransport();
            done("Calling getTransport(null) should throw an error.");
        } catch (ex) {
            done();
        }
    });
});
