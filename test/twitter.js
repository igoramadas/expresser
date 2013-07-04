// TEST: TWITTER

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Twitter Tests", function() {
    process.env.NODE_ENV = "test";

    var env = process.env;
    var settings = require("../lib/settings.coffee");
    var utils = null;
    var twitter = null;

    before(function() {
        utils = require("../lib/utils.coffee");
        utils.loadDefaultSettingsFromJson();

        twitter = require("../lib/twitter.coffee");
    });

    it("Is single instance", function() {
        twitter.singleInstance = true;
        var twitter2 = require("../lib/twitter.coffee");
        twitter.singleInstance.should.equal(twitter2.singleInstance);
    });

    it("Has settings defined", function() {
        settings.should.have.property("twitter");
    });

    it("Inits", function() {
        twitter.init();
    });
});