// TEST: TWITTER

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Twitter Tests", function() {

    var twitter = require("../lib/twitter.coffee");
    var settings = require("../lib/settings.coffee");

    it("Is single instance.", function() {
        twitter.singleInstance = true;
        var twitter2 = require("../lib/twitter.coffee");
        twitter.singleInstance.should.equal(twitter2.singleInstance);
    });

    it("Has settings defined.", function() {
        settings.should.have.property("twitter");
    });

    it("Inits.", function() {
        console.log("Twitter.init()");
        twitter.init();
    });
});