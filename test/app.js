// TEST: APP

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("App Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("settings.test.json");

    var app = null;
    var supertest = require("supertest");

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        app = require("../lib/app.coffee");

        if (settings.sockets) {
            settings.sockets.enabled = false;
        }
    });

    it("Has settings defined", function() {
        settings.should.have.property("app");
    });

    it("Inits", function() {
        this.timeout(10000);

        app.init();
    });

    it("Renders a test view", function(done) {
        this.timeout(10000);

        app.server.get("/testview", function(req, res) {
            app.renderView(req, res, "testview.pug");
        });

        supertest(app.server).get("/testview").expect(200, done);
    });

    it("Renders a JSON object", function(done) {
        this.timeout(10000);

        app.server.get("/testjson", function(req, res) {
            var j = {
                "string": "some value",
                "boolean": true,
                "int": 123,
                "date": new Date()
            }

            app.renderJson(req, res, j);
        });

        supertest(app.server).get("/testjson").expect("Content-Type", /json/).expect(200, done);
    });

    it("Renders an error with status 500", function(done) {
        this.timeout(10000);

        app.server.get("/testerror", function(req, res) {
            var e = {
                "somerror": new Error("Access was denied"),
                "timestamp": new Date().getTime()
            }

            app.renderError(req, res, e, 500);
        });

        supertest(app.server).get("/testerror").expect("Content-Type", /json/).expect(500, done);
    });
});
