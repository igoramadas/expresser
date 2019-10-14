// TEST: VIEW

let chai = require("chai")
let getPort = require("get-port")
let mocha = require("mocha")
let after = mocha.after
let before = mocha.before
let describe = mocha.describe
let it = mocha.it

chai.should()

describe("App View Tests", function() {
    let app = null
    let setmeup = null
    let settings = null
    let supertest = null

    before(async function() {
        let port = await getPort(8005)
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
        settings.app.viewEngine = "pug"

        app.init()
        supertest = require("supertest").agent(app.expressApp)
    })

    after(function() {
        if (app && app.kill) {
            app.kill()
        }
    })

    it("Renders a test PUG view", function(done) {
        app.get("/testview", function(req, res) {
            app.renderView(req, res, "testview.pug")
        })

        supertest.get("/testview").expect(200, done)
    })

    it("Renders a test PUG view passing options and status 403", function(done) {
        app.get("/testview-403", function(req, res) {
            app.renderView(req, res, "testview.pug", {title: "Access denied"}, 403)
        })

        supertest.get("/testview-403").expect(403, done)
    })

    it("Enable renderView event", function(done) {
        settings.app.events.render = true

        let callback = () => {
            app.off("renderView", callback)
            done()
        }

        app.get("/emitrender", function(req, res) {
            app.renderView(req, res, "testview.pug")
        })

        app.on("renderView", callback)
        supertest
            .get("/emitrender")
            .expect(200)
            .end(function() {})
    })
})
