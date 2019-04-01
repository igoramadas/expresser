// TEST: MIDDLEWARES

let chai = require("chai")
let getPort = require("get-port")
let mocha = require("mocha")
let after = mocha.after
let before = mocha.before
let describe = mocha.describe
let it = mocha.it

chai.should()

describe("App Middleware Tests", function() {
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
        settings.app.cookie.enabled = true
        settings.app.session.enabled = true
        settings.app.viewPath = "./test/"

        app.init()
        supertest = require("supertest").agent(app.expressApp)
    })

    after(function() {
        if (app && app.kill) {
            app.kill()
        }
    })

    it("Set and read request session", function(done) {
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
                })
            }
        })

        var setCallback = function(err) {
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
})
