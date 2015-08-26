// TEST: SOCKETS

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Sockets Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("../plugins/sockets/settings.default.json");
    settings.loadFromJson("settings.test.json");

    var utils = null;
    var sockets = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        utils = require("../lib/utils.coffee");
        sockets = require("../plugins/sockets/index.coffee");
    });

    it("Has settings defined", function() {
        settings.should.have.property("sockets");
    });
});
