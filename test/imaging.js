// TEST: IMAGING

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Imaging Tests", function() {
    process.env.NODE_ENV = "test";

    var env = process.env;
    var settings = require("../lib/settings.coffee");
    var utils = null;
    var imaging = null;

    before(function() {
        utils = require("../lib/utils.coffee");
        utils.loadDefaultSettingsFromJson();

        imaging = require("../lib/imaging.coffee");
    });

    it("Is single instance.", function() {
        imaging.singleInstance = true;
        var imaging2 = require("../lib/imaging.coffee");
        imaging.singleInstance.should.equal(imaging2.singleInstance);
    });
});