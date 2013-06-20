// TEST: DATABASE

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Database Tests", function() {

    var database = require("../lib/database.coffee");
    var settings = require("../lib/settings.coffee");
    var env = process.env;

    it("Is single instance.", function() {
        database.singleInstance = true;
        var database2 = require("../lib/database.coffee");
        database.singleInstance.should.equal(database2.singleInstance);
    });

    it("Has settings defined.", function() {
        settings.should.have.property("database");
    });

    it("Inits.", function() {
        database.init();
    });
});