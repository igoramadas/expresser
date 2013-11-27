// TEST: SOCKETS

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Sockets Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var utils = null;
    var sockets = null;

    before(function() {
        utils = require("../lib/utils.coffee");
        utils.loadDefaultSettingsFromJson();

        sockets = require("../lib/sockets.coffee");
    });

    it("Is single instance", function() {
        sockets.singleInstance = true;
        var sockets2 = require("../lib/sockets.coffee");
        sockets.singleInstance.should.equal(sockets2.singleInstance);
    });

    it("Has settings defined", function() {
        settings.should.have.property("sockets");
    });
});