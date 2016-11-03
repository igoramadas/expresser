// TEST: DATABASE MONGODB

require("coffee-script/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("Database MongoDB Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var database = null;
    var databaseMongo = null;
    var dbMongo = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function () {
        settings.loadFromJson("../plugins/database-mongodb/settings.default.json");
        settings.loadFromJson("settings.test.json");

        if (env["MONGODB"]) {
            settings.database.mongodb.connString = env["MONGODB"];
        }

        database = require("../lib/database.coffee").newInstance();

        databaseMongo = require("../plugins/database-mongodb/index.coffee");
        databaseMongo.expresser = require("../index.coffee");
        databaseMongo.expresser.events = require("../lib/events.coffee");
        databaseMongo.expresser.logger = require("../lib/logger.coffee");
        databaseMongo.expresser.database = database;
    });

    after(function () {
        var fs = require("fs");

        try {
            dbMongo.connection.close();
        } catch (ex) {
            console.error("Could not close MongoDB connection.", ex);
        }
    });

    it("Has settings defined", function () {
        settings.database.should.have.property("mongodb");
    });

    if (settings.database.mongodb && settings.database.mongodb.connString) {
        it("Inits", function () {
            database.init();
            dbMongo = databaseMongo.init();
        });

        it("MongoDB - Add complex record to the database", function (done) {
            this.timeout(10000);

            var callback = function (err, result) {
                if (err) {
                    done(err);
                } else {
                    done();
                }
            };

            var execution = function () {
                var obj = {
                    complex: true,
                    date: new Date(),
                    data: [1, 2, "a", "b", {
                        sub: 0.5
                    }]
                };
                dbMongo.insert("test", obj, callback);
            };

            setTimeout(execution, 2000);
        });

        it("MongoDB - Add 500 records to the database", function (done) {
            this.timeout(12000);

            var counter = 500;
            var current = 1;

            var callback = function (err, result) {
                if (err) {
                    done(err);
                } else if (current == counter) {
                    done();
                }

                current++;
            };

            var execution = function () {
                for (var i = 0; i < counter; i++) {
                    dbMongo.insert("test", {
                        counter: i
                    }, callback);
                }
            };

            setTimeout(execution, 100);
        });

        it("MongoDB - Updates all previously created records on the database", function (done) {
            var callback = function (err, result) {
                if (err) {
                    done(err);
                } else {
                    done();
                }
            };

            var obj = {
                $set: {
                    updated: true
                }
            };

            dbMongo.update("test", obj, callback);
        });
    } else {
        it.skip("Database MongoDB tests skipped, no connection string set");
    }
});