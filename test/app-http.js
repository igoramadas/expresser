// TEST: APP HTTP

require("coffeescript/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("App HTTP Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var app = null;
    var supertest = require("supertest");

    before(function () {
        settings.loadFromJson("settings.test.json");
        settings.app.port = 18001;
        settings.app.ssl.enabled = false;

        app = require("../lib/app.coffee").newInstance();
    });

    after(function () {
        app.kill();
    });

    it("Has app settings defined", function () {
        settings.should.have.property("app");
    });

    it("Init HTTP server with custom middleware, port 18001", function () {
        this.timeout(10000);

        var middleware = function (req, res, next) {
            if (req.path == "/middleware") {
                res.json({
                    ok: true
                });
            }

            next();
        };

        app.appendMiddlewares.push(middleware);
        app.init();
    });

    it("Renders a test view", function (done) {
        this.timeout(5000);

        app.server.get("/testview", function (req, res) {
            app.renderView(req, res, "testview.pug");
        });

        supertest(app.server).get("/testview").expect(200, done);
    });

    it("Renders a JSON object", function (done) {
        this.timeout(5000);

        app.server.get("/testjson", function (req, res) {
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

    it("Renders an error with status 500", function (done) {
        this.timeout(5000);

        app.server.get("/testerror", function (req, res) {
            var e = {
                "somerror": new Error("Access was denied"),
                "timestamp": new Date().getTime()
            }

            app.renderError(req, res, e, 500);
        });

        supertest(app.server).get("/testerror").expect("Content-Type", /json/).expect(500, done);
    });

    it("Renders a JPG image", function (done) {
        this.timeout(5000);

        app.server.get("/testjpg", function (req, res) {
            app.renderImage(req, res, __dirname + "/testimage.jpg");
        });

        supertest(app.server).get("/testjpg").expect("Content-Type", /image/).expect(200, done);
    });

    it("Test custom middleware on route /middleware", function (done) {
        this.timeout(5000);

        supertest(app.server).get("/middleware").expect("Content-Type", /json/).expect(200, done);
    });

    it("Kills the server", function () {
        app.kill();
    });
});
