// TEST: APP HTTPS

var env = process.env
var chai = require("chai")
var mocha = require("mocha")
var describe = mocha.describe
var before = mocha.before
var after = mocha.after
var it = mocha.it
chai.should()

describe("App HTTPS Tests", function() {
    env.NODE_ENV = "test"
    process.setMaxListeners(20)

    var https = require("http")
    https.globalAgent.maxSockets = 20

    var settings = require("../lib/settings.coffee")
    var app = null
    var supertest = null

    before(function() {
        settings.loadFromJson("settings.test.json")
        settings.app.port = 18002
        settings.app.ssl.enabled = true
        settings.app.ssl.keyFile = "localhost.key"
        settings.app.ssl.certFile = "localhost.crt"

        app = require("../lib/app.coffee").newInstance()
    })

    after(function() {
        app.kill()
    })

    it("Init HTTPS server with custom middleware array, port 18002", function() {
        this.timeout(10000)

        var middleware1 = function(req, res, next) {
            if (req.path == "/middleware1") {
                res.json({
                    middleware: 1
                })
            }

            next()
        }

        app.appendMiddlewares.push(middleware1)
        app.init()

        supertest = require("supertest").agent(app.expressApp)
    })

    it("Renders test middleware 1", function(done) {
        this.timeout(5000)

        supertest
            .get("/middleware1")
            .expect("Content-Type", /json/)
            .expect(200, done)
    })
})
