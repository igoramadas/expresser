// TEST: DATABASE

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Database Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    if (!settings.testKeysLoaded) {
        settings.loadFromJson("settings.test.keys.json");
        settings.testKeysLoaded = true;
    }
    
    var utils = null;
    var database = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        utils = require("../lib/utils.coffee");
        database = require("../lib/database.coffee");
    });

    it("Is single instance", function() {
        database.singleInstance = true;
        var database2 = require("../lib/database.coffee");
        database.singleInstance.should.equal(database2.singleInstance);
    });

    it("Has settings defined", function() {
        settings.should.have.property("database");
    });

    it("Inits", function() {
        database.init();
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

        database.insert("test", obj, callback);
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
            database.insert("test", {counter: i}, callback);
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

        database.update("test", obj, callback);
    });
});
