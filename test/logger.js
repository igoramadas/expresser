// TEST: LOGGER

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Logger Tests", function() {

    var logger = require("../lib/logger.coffee");
    var settings = require("../lib/settings.coffee");

    it("Is single instance.", function() {
        logger.singleInstance = true;
        var logger2 = require("../lib/logger.coffee");
        logger.singleInstance.should.equal(logger2.singleInstance);
    });

    it("Has settings defined.", function() {
        settings.should.have.property("logger");
    });

    it("Inits.", function() {
        console.log("Logger.init()");
        logger.init();
    });
});