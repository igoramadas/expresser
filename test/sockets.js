// TEST: SOCKETS

require("coffee-script/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("Sockets Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var utils = null;
    var sockets = null;

    before(function () {
        settings.loadFromJson("../plugins/sockets/settings.default.json");
        settings.loadFromJson("settings.test.json");

        utils = require("../lib/utils.coffee");
        sockets = require("../plugins/sockets/index.coffee");
    });

    it("Has settings defined", function () {
        settings.should.have.property("sockets");
    });
});