// TEST: MAIN

require("coffee-script/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("Expresser (Main) Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var expresser = require("../index.coffee");
    var events = require("../lib/events.coffee");

    before(function () {
        expresser.settings.loadFromJson("settings.test.json");
    });

    it("Inits", function () {
        var onInit = function () {
            done();
        }

        expresser.init();
    });
});