// TEST: APP HTTPS

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("App HTTPS Tests", function () {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("settings.test.json");
    settings.app.port = 18443;
    settings.app.ssl.enabled = true;
    settings.app.ssl.keyFile = "localhost.key";
    settings.app.ssl.certFile = "localhost.crt";

    var app = null;
    var supertest = require("supertest");

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function () {
        app = require("../lib/app.coffee").newInstance();
    });

    it("Init HTTPS server with custom middleware array, port 18443", function () {
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

        var options = {
            appendMiddlewares: [middleware1, middleware2]
        };

        app.init(options);
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