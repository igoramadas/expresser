// TEST: DATABASE

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Database Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("../plugins/database-file/settings.default.json");
    settings.loadFromJson("../plugins/database-mongodb/settings.default.json");
    settings.loadFromJson("../plugins/database-tingodb/settings.default.json");
    settings.loadFromJson("settings.test.json");

    if (env["MONGODB"]) {
        settings.database.mongodb.connString = env["MONGODB"];
    }

    var utils = null;
    var database = null;
    var databaseFile = null;
    var databaseMongo = null;
    var dbMongo = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        utils = require("../lib/utils.coffee");
        database = require("../lib/database.coffee");

        databaseFile = require("../plugins/database-file/index.coffee");
        databaseFile.expresser = require("../index.coffee");
        databaseFile.expresser.events = require("../lib/events.coffee");
        databaseFile.expresser.logger = require("../lib/logger.coffee");
        databaseFile.expresser.database = database;

        databaseMongo = require("../plugins/database-mongodb/index.coffee");
        databaseMongo.expresser = require("../index.coffee");
        databaseMongo.expresser.events = require("../lib/events.coffee");
        databaseMongo.expresser.logger = require("../lib/logger.coffee");
        databaseMongo.expresser.database = database;

        databaseTingo = require("../plugins/database-tingodb/index.coffee");
        databaseTingo.expresser = require("../index.coffee");
        databaseTingo.expresser.events = require("../lib/events.coffee");
        databaseTingo.expresser.logger = require("../lib/logger.coffee");
        databaseTingo.expresser.database = database;
    });

    after(function()
    {
        var fs = require("fs");

        try  {
            dbMongo.connection.close();
        } catch (ex) {
            console.error("Could not close MongoDB connection.", ex);
        }

        try {
            fs.unlinkSync(__dirname + "/database/test.json");
        } catch (ex) {
            console.error("Could not delete temporary test.json database file.", ex);
        }

        try {
            fs.unlinkSync(__dirname + "/database");
        } catch (ex) {
            console.error("Could not delete tingo.db test database.", ex);
        }
    });

    it("Has settings defined", function() {
        settings.should.have.property("database");
        settings.database.should.have.property("file");
        settings.database.should.have.property("mongodb");
        settings.database.should.have.property("tingodb");
    });

    it("Inits", function() {
        database.init();
        dbFile = databaseFile.init();
        dbMongo = databaseMongo.init();
        dbTingo = databaseTingo.init();
    });

    it("File - Add an array of random strings to database", function(done) {
        var callback = function(err, result) {
            if (err) {
                done(err);
            } else {
                done();
            }
        };

        var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-+";
        var arr = [];
        var a, b, max, text;

        for (a = 0; a < 100; a++) {
            max = Math.random() * 20;
            text = "";

            for (b = 0; b < max; b++) {
                text += chars.charAt(Math.floor(Math.random() * chars.length));
            }

            arr.push(text);
        }

        dbFile.insert("test", {id: "testArray", data: arr}, callback);
    });

    it("File - Remove test array created on previous test", function(done) {
        var callback = function(err, result) {
            if (err) {
                done(err);
            } else if (result == null) {
                done("Data was not found so couldn't be removed.");
            } else {
                done();
            }
        };

        dbFile.remove("test", {id: "testArray"}, callback);
    });

    it("MongoDB - Add complex record to the database", function(done) {
        this.timeout(10000);

        var callback = function(err, result) {
            if (err) {
                done(err);
            } else {
                done();
            }
        };

        var obj = {complex: true, date: new Date(), data: [1, 2, "a", "b", {sub: 0.5}]};

        dbMongo.insert("test", obj, callback);
    });

    it("MongoDB - Add 500 records to the database", function(done) {
        this.timeout(15000);

        var counter = 500;
        var current = 1;

        var callback = function(err, result) {
            if (err) {
                done(err);
            } else if (current == counter) {
                done();
            }

            current++;
        };

        for (var i = 0; i < counter; i++) {
            dbMongo.insert("test", {counter: i}, callback);
        }
    });

    it("MongoDB - Updates all previously created records on the database", function(done) {
        var callback = function(err, result) {
            if (err) {
                done(err);
            } else {
                done();
            }
        };

        var obj = {$set: {updated: true}};

        dbMongo.update("test", obj, callback);
    });

    it("TingoDB - Add complex record to the database", function(done) {
        var callback = function(err, result) {
            if (err) {
                done(err);
            } else {
                done();
            }
        };

        var obj = {complex: true, date: new Date(), data: [1, 2, "a", "b", {sub: 0.5}]};

        dbTingo.insert("test", obj, callback);
    });
});
