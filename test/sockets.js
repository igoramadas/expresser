// TEST: SOCKETS

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Sockets Tests", function() {
    process.env.NODE_ENV = "test";

    var env = process.env;
    var settings = null;
    var utils = null;
    var sockets = null;

    before(function() {
        settings = require("../lib/settings.coffee");
        utils = require("../lib/utils.coffee");
        utils.loadDefaultSettingsFromJson();

        sockets = require("../lib/sockets.coffee");
    });

    it("Is single instance.", function() {
        sockets.singleInstance = true;
        var sockets2 = require("../lib/sockets.coffee");
        sockets.singleInstance.should.equal(sockets2.singleInstance);
    });

    it("Has settings defined.", function() {
        settings.should.have.property("sockets");
    });
});