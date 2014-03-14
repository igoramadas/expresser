// TEST: UTILS

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Utils Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var utils;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        utils = require("../lib/utils.coffee");
    });

    it("Is single instance", function() {
        utils.singleInstance = true;
        var utils2 = require("../lib/utils.coffee");
        utils.singleInstance.should.equal(utils2.singleInstance);
    });
});