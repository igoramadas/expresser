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
        clearDatabase();

        settings.loadFromJson("../plugins/database-tingodb/settings.default.json");
        settings.loadFromJson("settings.test.json");

        database = require("../lib/database.coffee").newInstance();

        databaseTingo = require("../plugins/database-tingodb/index.coffee");
        databaseTingo.expresser = require("../index.coffee");
        databaseTingo.expresser.events = require("../lib/events.coffee");
        databaseTingo.expresser.logger = require("../lib/logger.coffee");
        databaseTingo.expresser.database = database;
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
            } else {
                done();
            }
        };

        var obj = {
            testId: testTimestamp,
            updated: false,
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
            } else if (result.length > 0 && result[0].testId == testTimestamp) {
                done();
            } else {
                done("Expected one result with testId = " + testTimestamp + ", but got something else.");
            }
        };

        var filter = {
            testId: testTimestamp
        };

        dbTingo.get("test", filter, callback);
    });

    it("Get all records from database", function (done) {
        var callback = function (err, result) {
            if (err) {
                done(err);
            } else {
                done();
            }
        };

        dbTingo.get("test", callback);
    });

    it("Updated record on database", function (done) {
        var callback = function (err, result) {
            if (err) {
                done(err);
            } else {
                done();
            }
        };
        
        var options = {
            filter: {
                testId: testTimestamp
            }
        };

        var obj = {
            updated: true
        };

        dbTingo.update("test", obj, callback);
    });

    it("Remove record from database", function (done) {
        var callback = function (err, result) {
            if (err) {
                done(err);
            } else {
                done();
            }
        };

        var filter = {
            testId: testTimestamp
        };

        dbTingo.remove("test", filter, callback);
    });

    it("Tries to get, insert, update using invalid params and connection", function (done) {
        var err = false;
        var connection = dbTingo.connection;

        dbTingo.connection = null;

        try {
            dbTingo.get();
            err = "DatabaseTingoDb.get(missing params) should throw an error, but did not.";
        } catch (ex) {}

        if (!err) {
            try {
                dbTingo.get("test", {something: true});
                err = "DatabaseTingoDb.get(invalid connection) should throw an error, but did not.";
            } catch (ex) {}
        }

        if (!err) {
            try {
                dbTingo.insert();
                err = "DatabaseTingoDb.insert(missing params) should throw an error, but did not.";
            } catch (ex) {}
        }

        if (!err) {
            try {
                dbTingo.insert("invalid", {});
                err = "DatabaseTingoDb.insert(invalid connection) should throw an error, but did not.";
            } catch (ex) {}
        }

        if (!err) {
            try {
                dbTingo.update();
                err = "DatabaseTingoDb.update(missing params) should throw an error, but did not.";
            } catch (ex) {}
        }

        if (!err) {
            try {
                dbTingo.update("invalid", {});
                err = "DatabaseTingoDb.update(invalid connection) should throw an error, but did not.";
            } catch (ex) {}
        }

        dbTingo.connection = connection;

        if (err) {
            done();
        } else {
            done(err);
        }
    });
});