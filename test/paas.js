// TEST: PAAS

require("coffee-script/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("PaaS Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var app = null;
    var database = null;
    var logger = null;
    var mailer = null;
    var paas = null;

    before(function () {
        settings.loadFromJson("settings.test.json");

        app = require("../lib/app.coffee").newInstance();
        database = require("../lib/database.coffee").newInstance();
        logger = require("../lib/logger.coffee").newInstance();
        mailer = require("../lib/mailer.coffee");

        paas = require("../lib/paas.coffee");
    });

    it("Has settings defined", function () {
        settings.should.have.property("paas");
    });

    it("Inits", function () {
        paas.init();
    });

    it("Updates app settings.", function () {
        app.init();


    });
});