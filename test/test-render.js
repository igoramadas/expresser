// TEST: RENDER

let chai = require("chai")
let getPort = require("get-port")
let mocha = require("mocha")
let after = mocha.after
let before = mocha.before
let describe = mocha.describe
let it = mocha.it

chai.should()

describe("App Render Tests", function() {
    let app = null
    let setmeup = null
    let settings = null
    let supertest = null

    before(async function() {
        let port = await getPort(8001)
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

        app.init()
        supertest = require("supertest").agent(app.expressApp)
    })

    after(function() {
        if (app && app.kill) {
            app.kill()
        }
    })

    it("Renders a plain text", function(done) {
        app.get("/plaintext", function(req, res) {
            app.renderText(req, res, "Hello world!")
        })

        supertest.get("/plaintext").expect(200, done)
    })

    it("Renders an empty text, passing status 404", function(done) {
        app.get("/emptytext", function(req, res) {
            app.renderText(req, res, null, 404)
        })

        supertest.get("/emptytext").expect(404, done)
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

    it("Renders a complex JSON object with allow origin header, status 202", function(done) {
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
                arr: [
                    function() {
                        return false
                    }
                ]
            }

            let final = {
                inner: inner,
                anotherFunc: () => {
                    return true
                }
            }

            app.renderJson(req, res, final, 202)
        })

        supertest
            .get("/complexjson")
            .expect("Content-Type", /json/)
            .expect(202, done)
    })

    it("Renders an error", function(done) {
        app.get("/testerror", function(req, res) {
            var e = new Error("Some error")
            e.status = "500"

            app.renderError(req, res, e)
        })

        supertest
            .get("/testerror")
            .expect("Content-Type", /json/)
            .expect(500, done)
    })

    it("Renders an error with status 401", function(done) {
        app.get("/testerror-401", function(req, res) {
            var e = {
                error: new Error("Access was denied"),
                statusCode: 401
            }

            e.error.code = "DENIED"

            app.renderError(req, res, e)
        })

        supertest
            .get("/testerror-401")
            .expect("Content-Type", /json/)
            .expect(401, done)
    })

    it("Renders an error from string", function(done) {
        app.get("/testerrorstring", function(req, res) {
            app.renderError(req, res, "This should be a JSON")
        })

        let resIsJson = function(res) {
            console.dir(res.body)
            res.body.should.have.property("message", "This should be a JSON")
        }

        supertest
            .get("/testerrorstring")
            .expect("Content-Type", /json/)
            .expect(resIsJson)
            .end(done)
    })

    it("Renders a timeout error", function(done) {
        app.get("/testerror-timeout", function(req, res) {
            app.renderError(req, res, "Timeout error", "ETIMEDOUT")
        })

        supertest
            .get("/testerror-timeout")
            .expect("Content-Type", /json/)
            .expect(408, done)
    })

    it("Renders error message from error.error_description", function(done) {
        app.get("/testerror-error_description", function(req, res) {
            var err = {
                error_description: "Some error description",
                friendlyMessage: "This is some friendly message"
            }
            app.renderError(req, res, err, 500)
        })

        supertest
            .get("/testerror-error_description")
            .expect("Content-Type", /json/)
            .expect(500, done)
    })

    it("Renders error message from error.description", function(done) {
        app.get("/testerror-description", function(req, res) {
            var err = {
                description: "Some error description",
                reason: "This is a reason"
            }
            app.renderError(req, res, err, 500)
        })

        supertest
            .get("/testerror-description")
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

    it("Renders a JPG image with options", function(done) {
        let options = {
            mimetype: "image/jpeg"
        }

        app.get("/testjpg-options", function(req, res) {
            app.renderImage(req, res, __dirname + "/testimage.jpg", options)
        })

        supertest
            .get("/testjpg-options")
            .expect("Content-Type", /image/)
            .expect(200, done)
    })

    it("Try rendering an invalid JSON, and disable event render", function(done) {
        settings.app.events.render = false

        app.get("/invalidjson", function(req, res) {
            app.renderJson(req, res, "invalid JSON / lalala")
        })

        supertest.get("/invalidjson").expect(500, done)
    })
})
