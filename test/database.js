// TEST: DATABASE

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Database Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
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

    it("Add simple record to the database", function(done) {
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

    it("Add complex record to the database", function(done) {
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