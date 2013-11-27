// TEST: APP

require("coffee-script");
var chai = require("chai");
chai.should();

describe("App Tests", function() {
    var settings = require("../lib/settings.coffee");
    var utils = null;
    var app = null;

    before(function() {
        utils = require("../lib/utils.coffee");
        utils.loadDefaultSettingsFromJson();

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