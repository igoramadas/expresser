// TEST: HTTPS

let chai = require("chai")
let getPort = require("get-port")
let mocha = require("mocha")
let after = mocha.after
let before = mocha.before
let describe = mocha.describe
let it = mocha.it

chai.should()

describe("App HTTPS Tests", function() {
    let app = null
    let setmeup = null
    let settings = null
    let supertest = null

    before(async function() {
        let port = await getPort(8003)
        let logger = require("anyhow")
        logger.setup("none")

        app = require("../lib/app").newInstance()
        setmeup = require("setmeup")
        settings = setmeup.settings
        settings.app.ip = "127.0.0.1"
        settings.app.port = port
        settings.app.ssl.enabled = true
        settings.app.ssl.rejectUnauthorized = false
        settings.app.ssl.keyFile = "test/localhost.key"
        settings.app.ssl.certFile = "test/localhost.crt"
        settings.app.compression.enabled = false
        settings.app.cookie.enabled = false
        settings.app.session.enabled = false
        settings.general.debug = true
    })

    after(function() {
        if (app && app.kill) {
            app.kill()
        }
    })

    it("Init HTTPS server on 127.0.0.1", function() {
        app.init()
        supertest = require("supertest").agent(app.expressApp)
    })

    it("Renders a JSON object via HTTPS", function(done) {
        app.get("/httpsjson", function(req, res) {
            var j = {
                encrypted: true
            }

            app.renderJson(req, res, j)
        })

        supertest
            .get("/httpsjson")
            .expect("Content-Type", /json/)
            .expect(200, done)
    })

    it("Kills the server", function(done) {
        app.once("kill", done)
        app.kill()
    })

    it("Fail to start with invalid certificates", function(done) {
        settings.app.ssl.certFile = "invalid.crt"

        try {
            app.start()
            return done("Starting with non existing certificate should throw an exception.")
        } catch (ex) {
            done()
        }
    })
})
