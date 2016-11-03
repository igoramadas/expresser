// TEST: APP ERRORS

require("coffee-script/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("App HTTP(s) Error Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var app = null;
    var supertest = require("supertest");

    before(function () {
        settings.loadFromJson("settings.test.json");
        settings.app.port = 18004;
        settings.app.ssl.enabled = false;

        app = require("../lib/app.coffee").newInstance();
    });

    it("Init HTTP server to test errors, port 18004", function () {
        this.timeout(10000);

        app.init();
    });

    it("Try rendering an invalid JSON", function (done) {
        this.timeout(5000);

        app.server.get("/invalidjson", function (req, res) {
            var invalidJson = "invalid JSON / lalala";

            app.renderJson(req, res, invalidJson);
        });

        supertest(app.server).get("/invalidjson").expect("Content-Type", /json/).expect(500, done);
    });
});