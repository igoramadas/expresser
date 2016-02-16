// TEST: DATABASE

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Database Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("../plugins/database-file/settings.default.json");
    settings.loadFromJson("../plugins/database-mongo/settings.default.json");
    settings.loadFromJson("settings.test.json");

    if (env["MONGO"]) {
        settings.database.mongo.connString = env["MONGO"];
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
        settings.database.should.have.property("file");
    });

    it("Inits", function() {
        database.init();
        dbFile = databaseFile.init();
        dbMongo = databaseMongo.init();
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

        dbFile.insert("test", arr, callback);
    });

    it("Mongo - Add complex record to the database", function(done) {
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

    it("Mongo - Add 500 records to the database", function(done) {
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

    it("Mongo - Updates all previously created records on the database", function(done) {
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
