// TEST: FIREWALL

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Firewall Tests", function() {
    process.env.NODE_ENV = "test";

    var env = process.env;
    var settings = null;
    var utils = null;
    var firewall = null;

    before(function() {
        settings = require("../lib/settings.coffee");
        utils = require("../lib/utils.coffee");
        utils.loadDefaultSettingsFromJson();

        firewall = require("../lib/firewall.coffee");
    });

    it("Is single instance.", function() {
        firewall.singleInstance = true;
        var firewall2 = require("../lib/firewall.coffee");
        firewall.singleInstance.should.equal(firewall2.singleInstance);
    });

    it("Has settings defined.", function() {
        settings.should.have.property("firewall");
    });
});