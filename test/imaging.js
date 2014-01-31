// TEST: IMAGING

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Imaging Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var utils = null;
    var imaging = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        utils = require("../lib/utils.coffee");

        imaging = require("../lib/imaging.coffee");
    });

    it("Is single instance", function() {
        imaging.singleInstance = true;
        var imaging2 = require("../lib/imaging.coffee");
        imaging.singleInstance.should.equal(imaging2.singleInstance);
    });
});