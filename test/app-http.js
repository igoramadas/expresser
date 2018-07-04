// TEST: APP HTTP

require("coffeescript/register")
var env = process.env
var chai = require("chai")
chai.should()

describe("App HTTP Tests", function() {
    env.NODE_ENV = "test"
    process.setMaxListeners(20)

    var http = require("http")
    http.globalAgent.maxSockets = 20

    var settings = require("../lib/settings.coffee")
    var app = null
    var supertest = null

    before(function() {
        settings.loadFromJson("settings.test.json")
        settings.app.port = 18001
        settings.app.ssl.enabled = false

        app = require("../lib/app.coffee").newInstance()
    })

    after(function() {
        app.kill()
    })

    it("Has app settings defined", function() {
        settings.should.have.property("app")
    })

    it("Init HTTP server with custom middleware, port 18001", function() {
        this.timeout(10000)

        var middleware = function(req, res, next) {
            if (req.path == "/middleware") {
                res.json({
                    ok: true
                })
            }

            next()
        }

        app.appendMiddlewares.push(middleware)
        app.init()

        supertest = require("supertest").agent(app.expressApp)
    })

    it("Renders a test view", function(done) {
        this.timeout(5000)

        app.get("/testview", function(req, res) {
            app.renderView(req, res, "testview.pug")
        })

        supertest.get("/testview").expect(200, done)
    })

    it("Renders a plain text", function(done) {
        this.timeout(5000)

        app.get("/plaintext", function(req, res) {
            app.renderText(req, res, "hello world")
        })

        supertest.get("/plaintext").expect(200, done)
    })

    it("Renders a JSON object", function(done) {
        this.timeout(5000)

        app.get("/testjson", function(req, res) {
            var j = {
                string: "some value",
                boolean: true,
                int: 123,
                date: new Date()
            }

            app.renderJson(req, res, j)
        })

        supertest
            .get("/testjson")
            .expect("Content-Type", /json/)
            .expect(200, done)
    })

    it("Renders an error with status 500", function(done) {
        this.timeout(5000)

        app.get("/testerror", function(req, res) {
            var e = {
                somerror: new Error("Access was denied"),
                timestamp: new Date().getTime()
            }

            app.renderError(req, res, e, 500)
        })

        supertest
            .get("/testerror")
            .expect("Content-Type", /json/)
            .expect(500, done)
    })

    it("Renders a JPG image", function(done) {
        this.timeout(5000)

        app.get("/testjpg", function(req, res) {
            app.renderImage(req, res, __dirname + "/testimage.jpg")
        })

        supertest
            .get("/testjpg")
            .expect("Content-Type", /image/)
            .expect(200, done)
    })

    it("Set and read request session", function(done) {
        this.timeout(5000)

        app.get("/setsession", function(req, res) {
            req.session.something = "ABC"
            app.renderJson(req, res, {
                session: true
            })
        })

        app.get("/getsession", function(req, res) {
            if (req.session.something == "ABC") {
                app.renderJson(req, res, {
                    session: true
                })
            } else {
                app.renderError(req, res, {
                    session: false
                }, 500)
            }
        })

        var setCallback = async function(err) {
            if (err) {
                done(err)
            } else {
                var getSession = function() {
                    supertest.get("/getsession").expect(200, done)
                }
                setTimeout(getSession, 200)
            }
        }

        supertest.get("/setsession").expect(200, setCallback)
    })

    it("Test custom middleware on route /middleware", function(done) {
        this.timeout(5000)

        supertest
            .get("/middleware")
            .expect("Content-Type", /json/)
            .expect(200, done)
    })

    it("Lists all registered routes on the server", function(done) {
        var routes = app.listRoutes()
        var simpleRoutes = app.listRoutes(true)

        if (simpleRoutes.length == routes.length) {
            done()
        } else {
            done("The getRoutes should return same length for when `asString` is true or false.")
        }
    })

    it("Kills the server", function() {
        app.kill()
    })
})
