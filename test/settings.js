// TEST: SETTINGS

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Settings Tests", function() {

    var settings = require("../lib/settings.coffee");

    it("Is single instance.", function() {
        settings.singleInstance = true;
        var settings2 = require("../lib/settings.coffee");
        settings.singleInstance.should.equal(settings2.singleInstance);
    });

    it("Has all module settings defined.", function() {
        settings.should.have.property("general");
        settings.should.have.property("app");
        settings.should.have.property("database");
        settings.should.have.property("firewall");
        settings.should.have.property("logger");
        settings.should.have.property("mail");
        settings.should.have.property("sockets");
        settings.should.have.property("twitter");
    });
});