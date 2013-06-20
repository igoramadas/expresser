// TEST: DATABASE

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Database Tests", function() {

    var database = require("../lib/database.coffee");
    var settings = require("../lib/settings.coffee");
    var env = process.env;

    it("Is single instance.", function() {
        database.singleInstance = true;
        var database2 = require("../lib/database.coffee");
        database.singleInstance.should.equal(database2.singleInstance);
    });

    it("Has settings defined.", function() {
        settings.should.have.property("database");
    });

    it("Init (connect on localhost).", function() {
        settings.database.connString = "mongodb://127.0.0.1/expresser"
        database.init();
    });

    it("Add simple record to the database.", function(done) {
        var callback = function(err, result) {
            if (err) {
                throw err;
            } else {
                done();
            }
        };

        var obj = {simple: true};

        database.set("test", obj, callback);
    });

    it("Add complex record to the database.", function(done) {
        var callback = function(err, result) {
            if (err) {
                throw err;
            } else {
                done();
            }
        };

        var obj = {complex: true, date: new Date(), data: [1, 2, "a", "b", {sub: 0.5}]};

        database.set("test", obj, callback);
    });
});