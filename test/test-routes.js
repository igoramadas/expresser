// TEST: ROUTES

let chai = require("chai")
let getPort = require("get-port")
let mocha = require("mocha")
let after = mocha.after
let before = mocha.before
let describe = mocha.describe
let it = mocha.it

chai.should()

describe("App Routes Tests", function() {
    let app = null
    let routes = null
    let setmeup = null
    let settings = null
    let supertest = null

    let handlers = {
        getHome: (req, res) => {
            res.send("home")
        },
        getAbc: (req, res) => {
            res.send("abc")
        },
        postAbc: (req, res) => {
            res.send("post")
        },
        getDef: (req, res) => {
            res.send("def")
        },
        getSwaggerAbc: (req, res) => {
            res.json({ok: true})
        }
    }

    before(async function() {
        let port = await getPort(8008)
        let logger = require("anyhow")
        logger.setup("none")

        app = require("../lib/app")
        routes = require("../lib/routes")
        setmeup = require("setmeup")
        settings = setmeup.settings
        settings.app.port = port
        settings.app.ssl.enabled = false
        settings.app.compression.enabled = false
        settings.app.cookie.enabled = false
        settings.app.session.enabled = false
        settings.app.events.render = false
        settings.routes.filename = "./test/sampleroutes.json"
        settings.routes.swagger.filename = "./test/sampleswagger.json"

        app.init()
        supertest = require("supertest").agent(app.expressApp)
    })

    after(function() {
        if (app && app.kill) {
            app.kill()
        }
    })

    it("Has settings defined", function() {
        settings.should.have.property("routes")
    })

    it("Load routes from default file", function(done) {
        routes.load({handlers: handlers})

        supertest.get("/").expect(200)
        supertest.get("/abc").expect(200)
        supertest.post("/abc").expect(200, done)
    })

    it("Fails to load routes from incorrect files", function(done) {
        try {
            routes.load({filename: "notexisting.json"})
            done("Calling load with non existing file should have failed.")
        } catch (ex) {
            try {
                routes.load({filename: "./test/testview.pug"})
                done("Calling load passing an invalid JSON file should have failed.")
            } catch (ex) {
                done()
            }
        }
    })

    it("Fails to load routes with missing handlers", function(done) {
        try {
            routes.load()
            done("Calling load without passing handles should have failed.")
        } catch (ex) {
            done()
        }
    })

    it("Load swagger from default file", function(done) {
        routes.loadSwagger({handlers: handlers})

        supertest.get("/swagger/abc").expect(200, done)
    })

    it("Fails to load swagger specs from incorrect files", function(done) {
        try {
            routes.loadSwagger({filename: "notexisting.json"})
            done("Calling loadSwagger with non existing file should have failed.")
        } catch (ex) {
            try {
                routes.loadSwagger({filename: "./test/testview.pug"})
                done("Calling loadSwagger passing an invalid JSON file should have failed.")
            } catch (ex) {
                done()
            }
        }
    })

    it("Fails to load swagger specs with missing handlers", function(done) {
        try {
            routes.loadSwagger()
            done("Calling loadSwagger without passing handles should have failed.")
        } catch (ex) {
            done()
        }
    })
})
