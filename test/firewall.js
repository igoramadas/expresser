// TEST: FIREWALL

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Firewall Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    if (!settings.testKeysLoaded) {
        settings.loadFromJson("settings.test.keys.json");
        settings.testKeysLoaded = true;
    }

    var utils = null;
    var firewall = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        utils = require("../lib/utils.coffee");

        firewall = require("../plguins/firewall/index.coffee");
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
