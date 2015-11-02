// TEST: DATABASE

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Database Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("../plugins/database-mongo/settings.default.json");
    settings.loadFromJson("settings.test.json");

    if (env["MONGO"]) {
        settings.database.mongo.connString = env["MONGO"];
    }

    var utils = null;
    var database = null;
    var databaseMongo = null;
    var dbMongo = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        utils = require("../lib/utils.coffee");
        database = require("../lib/database.coffee");
        databaseMongo = require("../plugins/database-mongo/index.coffee");
        databaseMongo.expresser = require("../index.coffee");
        databaseMongo.expresser.events = require("../lib/events.coffee");
        databaseMongo.expresser.logger = require("../lib/logger.coffee");
        databaseMongo.expresser.database = database;
    });

    after(function()
    {
        try { dbMongo.connection.close(); } catch (ex) { }

    });

    it("Has settings defined", function() {
        settings.should.have.property("database");
        settings.database.should.have.property("mongo");
    });

    it("Inits", function() {
        database.init();
        dbMongo = databaseMongo.init();
    });

    it("Add complex record to the database", function(done) {
        this.timeout(10000);

        var callback = function(err, result) {
            if (err) {
                throw err;
            } else {
                done();
            }
        };

        var obj = {complex: true, date: new Date(), data: [1, 2, "a", "b", {sub: 0.5}]};

        dbMongo.insert("test", obj, callback);
    });

    it("Add 500 records to the database", function(done) {
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

    it("Updates all previously created records on the database", function(done) {
        var callback = function(err, result) {
            if (err) {
                throw err;
            } else {
                done();
            }
        };

        var obj = {$set: {updated: true}};

        dbMongo.update("test", obj, callback);
    });
});
