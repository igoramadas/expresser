// TEST: SOCKETS

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Sockets Tests", function() {

    var sockets = require("../lib/sockets.coffee");
    var settings = require("../lib/settings.coffee");

    it("Is single instance.", function() {
        sockets.singleInstance = true;
        var sockets2 = require("../lib/sockets.coffee");
        sockets.singleInstance.should.equal(sockets2.singleInstance);
    });

    it("Has settings defined.", function() {
        settings.should.have.property("sockets");
    });
});