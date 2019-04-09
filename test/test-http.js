// TEST: HTTP

let chai = require("chai")
let getPort = require("get-port")
let mocha = require("mocha")
let after = mocha.after
let before = mocha.before
let describe = mocha.describe
let it = mocha.it

chai.should()

describe("App Main Tests", function() {
    let app = null
    let setmeup = null
    let settings = null
    let supertest = null

    before(async function() {
        let port = await getPort(8000)
        let logger = require("anyhow")
        logger.setup("none")

        app = require("../lib/app").newInstance()
        setmeup = require("setmeup")
        settings = setmeup.settings
        settings.app.port = port
        settings.app.ssl.enabled = false
        settings.app.compression.enabled = false
        settings.app.cookie.enabled = false
        settings.app.session.enabled = false
        settings.app.events.render = true
        settings.app.viewPath = "./test/"
    })

    after(function() {
        if (app && app.kill) {
            app.kill()
        }
    })

    it("Has settings defined", function() {
        settings.should.have.property("app")
    })

    it("Fail to call Express application methods before App init", function(done) {
        let methods = ["get", "post", "listen", "route", "use"]
        let failed = false

        for (let m = 0; m < methods.length; m++) {
            try {
                app[methods[m]]({})
                done("Method " + methods[m] + " should throw exception before app has initiated.")
                failed = true
                m = methods.length
            } catch (ex) {}
        }

        if (!failed) {
            done()
        }
    })

    it("Init HTTP server with custom middlewares", function() {
        let prepend = function(req, res, next) {
            if (req.path == "/prepend") {
                res.json({
                    ok: true
                })
            }
            next()
        }

        let append = function(req, res, next) {
            if (req.path == "/append") {
                res.json({
                    ok: true
                })
            }
            next()
        }

        let middlewares = {
            prepend: prepend,
            append: append
        }

        app.init(middlewares)
        supertest = require("supertest").agent(app.expressApp)
    })

    it("Renders a plain text", function(done) {
        app.get("/plaintext", function(req, res) {
            app.renderText(req, res, "Hello world!")
        })

        supertest.get("/plaintext").expect(200, done)
    })

    it("Renders an empty text", function(done) {
        app.get("/emptytext", function(req, res) {
            app.renderText(req, res, null)
        })

        supertest.get("/emptytext").expect(200, done)
    })

    it("Renders number as text", function(done) {
        app.get("/numbertext", function(req, res) {
            app.renderText(req, res, 123)
        })

        supertest.get("/numbertext").expect(200, done)
    })

    it("Renders a simple JSON object", function(done) {
        app.get("/testjson", function(req, res) {
            let j = {
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

    it("Renders a complex JSON object with allow origin header", function(done) {
        settings.app.allowOriginHeader = true

        app.get("/complexjson", function(req, res) {
            let j = {
                string: "some value",
                boolean: true,
                int: 123,
                date: new Date()
            }

            let inner = {
                something: {
                    inside: [1, false, j],
                    more: {
                        deep: {
                            inside: {
                                obj: {
                                    hello: {
                                        there: 1
                                    }
                                }
                            }
                        }
                    }
                },
                func: function() {
                    return false
                }
            }

            let final = {
                inner: inner
            }

            app.renderJson(req, res, final)
        })

        supertest
            .get("/complexjson")
            .expect("Content-Type", /json/)
            .expect(200, done)
    })

    it("Renders an error with status 500", function(done) {
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
        app.get("/testjpg", function(req, res) {
            app.renderImage(req, res, __dirname + "/testimage.jpg")
        })

        supertest
            .get("/testjpg")
            .expect("Content-Type", /image/)
            .expect(200, done)
    })

    it("Test prepended middleware on route /prepend", function(done) {
        supertest
            .get("/prepend")
            .expect("Content-Type", /json/)
            .expect(200, done)
    })

    it("Test appended middleware on route /append", function(done) {
        supertest
            .get("/append")
            .expect("Content-Type", /json/)
            .expect(200, done)
    })

    it("Try rendering an invalid JSON, and disable event render", function(done) {
        settings.app.events.render = false

        app.get("/invalidjson", function(req, res) {
            app.renderJson(req, res, "invalid JSON / lalala")
        })

        supertest.get("/invalidjson").expect(500, done)
    })

    it("Lists all registered routes on the server", function(done) {
        done()
        let routes = app.listRoutes()
        let simpleRoutes = app.listRoutes(true)

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
