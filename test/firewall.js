// TEST: FIREWALL

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Firewall Tests", function() {

    var firewall = require("../lib/firewall.coffee");
    var settings = require("../lib/settings.coffee");

    it("Is single instance.", function() {
        firewall.singleInstance = true;
        var firewall2 = require("../lib/firewall.coffee");
        firewall.singleInstance.should.equal(firewall2.singleInstance);
    });

    it("Has settings defined.", function() {
        settings.should.have.property("firewall");
    });
});