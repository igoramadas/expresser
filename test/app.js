// TEST: APP

require("coffee-script");
var chai = require("chai");
chai.should();

describe("App Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var app;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        app = require("../lib/app.coffee");
    });

    it("Is single instance", function() {
        app.singleInstance = true;
        var app2 = require("../lib/app.coffee");
        app.singleInstance.should.equal(app2.singleInstance);
    });

    it("Has settings defined", function() {
        settings.should.have.property("app");
    });

    it("Inits", function() {
        app.init();
    });
});