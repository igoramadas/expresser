// TEST: FIREWALL

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Firewall Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var utils = null;
    var firewall = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        utils = require("../lib/utils.coffee");
        utils.loadDefaultSettingsFromJson();

        firewall = require("../lib/firewall.coffee");
    });

    it("Is single instance", function() {
        firewall.singleInstance = true;
        var firewall2 = require("../lib/firewall.coffee");
        firewall.singleInstance.should.equal(firewall2.singleInstance);
    });

    it("Has settings defined", function() {
        settings.should.have.property("firewall");
    });
});