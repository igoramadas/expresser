// TEST: IMAGING

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Imaging Tests", function() {

    var imaging = require("../lib/imaging.coffee");
    var settings = require("../lib/settings.coffee");

    it("Is single instance.", function() {
        imaging.singleInstance = true;
        var imaging2 = require("../lib/imaging.coffee");
        imaging.singleInstance.should.equal(imaging2.singleInstance);
    });

    it("Has settings defined.", function() {
        settings.should.have.property("imaging");
    });
});