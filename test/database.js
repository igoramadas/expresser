// TEST: DATABASE

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Database Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("../plugins/database-tingodb/settings.default.json");
    settings.loadFromJson("../plugins/database-mongodb/settings.default.json");
    settings.loadFromJson("settings.test.json");

    if (env["MONGODB"]) {
        settings.database.mongodb.connString = env["MONGODB"];
    }

    var utils = null;
    var database = null;
    var databaseTingo = null;
    var databaseMongo = null;
    var dbTingo = null;
    var dbMongo = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        utils = require("../lib/utils.coffee");
        database = require("../lib/database.coffee");

        databaseTingo = require("../plugins/database-tingodb/index.coffee");
        databaseTingo.expresser = require("../index.coffee");
        databaseTingo.expresser.events = require("../lib/events.coffee");
        databaseTingo.expresser.logger = require("../lib/logger.coffee");
        databaseTingo.expresser.database = database;

        databaseMongo = require("../plugins/database-mongodb/index.coffee");
        databaseMongo.expresser = require("../index.coffee");
        databaseMongo.expresser.events = require("../lib/events.coffee");
        databaseMongo.expresser.logger = require("../lib/logger.coffee");
        databaseMongo.expresser.database = database;
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
            fs.unlinkSync(__dirname + "/database");
        } catch (ex) {
            console.error("Could not delete TingoDB test database files.", ex);
        }
    });

    it("Has settings defined", function() {
        settings.should.have.property("database");
        settings.database.should.have.property("tingodb");
        settings.database.should.have.property("mongodb");
    });

    it("Inits", function() {
        database.init();
        dbTingo = databaseTingo.init();
        dbMongo = databaseMongo.init();
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


    it("MongoDB - Add complex record to the database", function(done) {
        this.timeout(10000);

        var callback = function(err, result) {
            if (err) {
                done(err);
            } else {
                done();
            }
        };

        var execution = function() {
            var obj = {complex: true, date: new Date(), data: [1, 2, "a", "b", {sub: 0.5}]};
            dbMongo.insert("test", obj, callback);
        };

        setTimeout(execution, 2000);
    });

    it("MongoDB - Add 500 records to the database", function(done) {
        this.timeout(12000);

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

        var execution = function() {
            for (var i = 0; i < counter; i++) {
                dbMongo.insert("test", {counter: i}, callback);
            }
        };

        setTimeout(execution, 100);
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
});
