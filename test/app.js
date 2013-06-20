// TEST: APP

require("coffee-script");
var chai = require("chai");
chai.should();

describe("App Tests", function() {

    var app = require("../lib/app.coffee");
    var settings = require("../lib/settings.coffee");
    var env = process.env;

    it("Is single instance.", function() {
        app.singleInstance = true;
        var app2 = require("../lib/app.coffee");
        app.singleInstance.should.equal(app2.singleInstance);
    });

    it("Has settings defined.", function() {
        settings.should.have.property("app");
    });

    it("Inits.", function() {
        app.init();
    });
});