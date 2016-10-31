// TEST: APP

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("App Tests", function () {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("settings.test.json");

    var app = null;
    var sockets = null;
    var supertest = require("supertest");

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function () {
        app = require("../lib/app.coffee");
        sockets = require("../plugins/sockets/index.coffee");

        sockets.expresser = require("../index.coffee");
        sockets.expresser.events = require("../lib/events.coffee");
        sockets.expresser.logger = require("../lib/logger.coffee");
    });

    it("Has app settings defined", function () {
        settings.should.have.property("app");
    });

    it("Has sockets settings defined", function () {
        settings.should.have.property("sockets");
    });

    it("Init app server", function () {
        this.timeout(10000);

        app.init();
    });

    it("Init sockets", function () {
        this.timeout(10000);

        sockets.bind(app.server);
    });

    it("Renders a test view", function (done) {
        this.timeout(10000);

        app.server.get("/testview", function (req, res) {
            app.renderView(req, res, "testview.pug");
        });

        supertest(app.server).get("/testview").expect(200, done);
    });

    it("Renders a JSON object", function (done) {
        this.timeout(10000);

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
        this.timeout(10000);

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
        this.timeout(10000);

        app.server.get("/testjpg", function (req, res) {
            app.renderImage(req, res, __dirname + "/testimage.jpg");
        });

        supertest(app.server).get("/testjpg").expect("Content-Type", /image/).expect(200, done);
    });

    it("Emits and intercept a message via sockets", function (done) {
        this.timeout(10000);

        var listener = function (value) {
            if (value == true) {
                return done();
            }
            done("Expected socket message value is true, but got " + value + ".");
        };

        var connected = function (err, res) {
            if (err) {
                return done(err);
            }
            sockets.emit("test-socket", true);
        };

        var trigger = function () {
            supertest(app.server).get("/testsocket").expect(200, connected);
        };

        app.server.get("/testsocket", function (req, res) {
            app.renderView(req, res, "testsocket.pug");
        });

        sockets.listenTo("test-socket", listener, false);
        setTimeout(trigger, 100);
    });
});