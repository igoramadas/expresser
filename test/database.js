// TEST: DATABASE

require("coffeescript/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("Database Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var database = null;

    before(function () {
        settings.loadFromJson("settings.test.json");

        database = require("../lib/database.coffee").newInstance();
    });

    it("Has settings defined", function () {
        settings.should.have.property("database");
    });

    it("Inits", function () {
        database.init();
    });

    it("Try to register invalid database driver", function (done) {
        if (!database.register("invalid", "invalid")) {
            done();
        } else {
            done("Database.register(invalid) should log an error and return false, but it didn't.")
        }
    });
});
