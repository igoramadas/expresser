// TEST: APP HTTPS

require("coffeescript/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("App HTTPS Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var app = null;
    var supertest = require("supertest");

    before(function () {
        settings.loadFromJson("settings.test.json");
        settings.app.port = 18002;
        settings.app.ssl.enabled = true;
        settings.app.ssl.keyFile = "localhost.key";
        settings.app.ssl.certFile = "localhost.crt";

        app = require("../lib/app.coffee").newInstance();
    });

    after(function () {
        app.kill();
    });

    it("Init HTTPS server with custom middleware array, port 18002", function () {
        this.timeout(10000);

        var middleware1 = function (req, res, next) {
            if (req.path == "/middleware1") {
                res.json({
                    middleware: 1
                });
            }

            next();
        };

        var middleware2 = function (req, res, next) {
            if (req.path == "/middleware2") {
                res.json({
                    middleware: 2
                });
            }

            next();
        };

        app.appendMiddlewares.push(middleware1);
        app.appendMiddlewares.push(middleware2);
        app.init();
    });

    it("Renders test middleware 1", function (done) {
        this.timeout(5000);

        supertest(app.server).get("/middleware1").expect("Content-Type", /json/).expect(200, done);
    });

    it("Renders test middleware 2", function (done) {
        this.timeout(5000);

        supertest(app.server).get("/middleware2").expect("Content-Type", /json/).expect(200, done);
    });
});
