// TEST: DATABASE TINGODB

require("coffee-script/register");
var env = process.env;
var chai = require("chai");
var fs = require("fs");
chai.should();

describe("Database TingoDB Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var testTimestamp = require("moment")().valueOf();
    var settings = require("../lib/settings.coffee");
    var database = null;
    var databaseTingo = null;
    var dbTingo = null;

    var clearDatabase = function () {
        try {
            if (fs.existsSync(__dirname + "/database/test.tingo")) {
                fs.unlinkSync(__dirname + "/database/test.tingo");
            }
        } catch (ex) {
            console.error("Could not delete TingoDB test database files.", ex);
        }
    };

    before(function () {
        settings.loadFromJson("../plugins/database-tingodb/settings.default.json");
        settings.loadFromJson("settings.test.json");

        database = require("../lib/database.coffee").newInstance();

        databaseTingo = require("../plugins/database-tingodb/index.coffee");
        databaseTingo.expresser = require("../index.coffee");
        databaseTingo.expresser.events = require("../lib/events.coffee");
        databaseTingo.expresser.logger = require("../lib/logger.coffee");
        databaseTingo.expresser.database = database;

        clearDatabase();
    });

    after(function () {
        clearDatabase();
    });

    it("Has settings defined", function () {
        settings.database.should.have.property("tingodb");
    });

    it("Inits", function () {
        database.init();
        dbTingo = databaseTingo.init();
    });

    it("Add complex record to the database", function (done) {
        var callback = function (err, result) {
            if (err) {
                done(err);
            } else if (result.length > 0 && result[0].testId == testTimestamp) {
                done();
            } else {
                done("Expected one result with testId = " + testTimestamp + ", but got something else.");
            }
        };

        var obj = {
            testId: testTimestamp,
            complex: true,
            date: new Date(),
            data: [1, 2, "a", "b", {
                sub: 0.5
            }]
        };

        dbTingo.insert("test", obj, callback);
    });

    it("Get record added on the previous step", function (done) {
        var callback = function (err, result) {
            if (err) {
                done(err);
            } else {
                done();
            }
        };

        var obj = {
            complex: true,
            date: new Date(),
            data: [1, 2, "a", "b", {
                sub: 0.5
            }]
        };

        var filter = {
            complex: true
        };

        dbTingo.get("test", filter, callback);
    });
});