// TEST: DATABASE

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Database Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("settings.test.json");
    
    var database = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        database = require("../lib/database.coffee").newInstance();
    });

    it("Has settings defined", function() {
        settings.should.have.property("database");
    });

    it("Inits", function() {
        database.init();
    });
});
