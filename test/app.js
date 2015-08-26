// TEST: APP

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("App Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("settings.test.json");

    var app;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        app = require("../lib/app.coffee");
    });

    it("Has settings defined", function() {
        settings.should.have.property("app");
    });
});
