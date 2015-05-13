// TEST: DATABASE (MONGODB)

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Database (MongoDB) Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    if (!settings.testKeysLoaded) {
        settings.loadFromJson("settings.test.keys.json");
        settings.testKeysLoaded = true;
    }

    var expresser = null;
    var utils = null;
    var database = null;
    var databaseMongo = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {

        utils = require("../lib/utils.coffee");
        database = require("../lib/database.coffee");
        databaseMongo = require("../plugins/database-mongo/index.js");
        databaseMongo.expresser = require("../index.coffee");
    });

    it("Has settings defined", function() {
        settings.database.should.have.property("mongo");
    });

    it("Inits", function() {
        expresser.init();
        database.init();
        databaseMongo.init();
    });

    it("Add simple record to the database", function(done) {
        var callback = function(err, result) {
            if (err) {
                throw err;
            } else {
                done();
            }
        };

        var obj = {simple: true};

        databaseMongo.insert("test", obj, callback);
    });

    it("Add complex record to the database", function(done) {
        var callback = function(err, result) {
            if (err) {
                throw err;
            } else {
                done();
            }
        };

        var obj = {complex: true, date: new Date(), data: [1, 2, "a", "b", {sub: 0.5}]};

        database.insert("test", obj, callback);
    });

    it("Add 500 records to the database", function(done) {
        this.timeout(20000);

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
            databaseMongo.insert("test", {counter: i}, callback);
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

        var obj = {updated: true};

        databaseMongo.update("test", obj, callback);
    });
});
