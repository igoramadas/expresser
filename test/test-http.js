// TEST: HTTP

let chai = require("chai")
let getPort = require("get-port")
let mocha = require("mocha")
let after = mocha.after
let before = mocha.before
let describe = mocha.describe
let it = mocha.it

chai.should()

describe("App HTTP Tests", function () {
    let app = null
    let setmeup = null
    let settings = null
    let supertest = null

    before(async function () {
        let port = await getPort(8002)
        let logger = require("anyhow")
        logger.setup("none")

        app = require("../lib/index").app.newInstance()
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

    after(function () {
        if (app && app.kill) {
            app.kill()
        }
    })

    it("Has settings defined", function () {
        settings.should.have.property("app")
    })

    it("Fail to call Express application methods before App init", function (done) {
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

    it("Init HTTP server", function () {
        app.init()
        supertest = require("supertest").agent(app.expressApp)
    })

    it("Request set property", function () {
        app.set("trust proxy", 1)
    })

    it("Request all", function (done) {
        app.get("/all", function (req, res) {
            res.send("ok")
        })

        supertest.get("/all").expect(200, done)
    })

    it("Request get", function (done) {
        app.get("/get", function (req, res) {
            res.send("ok")
        })

        supertest.get("/get").expect(200, done)
    })

    it("Request post json", function (done) {
        app.post("/post-json", function (req, res) {
            res.send("ok")

            if (req.body && req.body.hello == 123) {
                done()
            } else {
                done(`Request body does not have hello=123`)
            }
        })

        supertest
            .post("/post-json")
            .send({hello: 123})
            .expect(200)
            .end((err) => {
                if (err) done(err)
            })
    })

    it("Request post text", function (done) {
        app.post("/post-text", function (req, res) {
            res.send("ok")

            if (req.body && req.body == "Hello world") {
                done()
            } else {
                done(`Request body should be "Hello world"`)
            }
        })

        supertest
            .post("/post-text")
            .set({"Content-Type": "text/plain"})
            .send("Hello world")
            .expect(200)
            .end((err) => {
                if (err) done(err)
            })
    })

    it("Request post octet", function (done) {
        app.post("/post-octet", function (req, res) {
            res.send("ok")

            if (req.body && req.body == "101010") {
                done()
            } else {
                done(`Request body should be "101010"`)
            }
        })

        supertest
            .post("/post-octet")
            .set({"Content-Type": "application/octet-stream"})
            .send("101010")
            .expect(200)
            .end((err) => {
                if (err) done(err)
            })
    })

    it("Request patch", function (done) {
        app.patch("/patch", function (req, res) {
            res.send("ok")
        })

        supertest.patch("/patch").expect(200, done)
    })

    it("Request put", function (done) {
        app.put("/put", function (req, res) {
            res.send("ok")
        })

        supertest.put("/put").expect(200, done)
    })

    it("Request use", function (done) {
        app.use("/use", function (req, res) {
            res.send("ok")
        })

        supertest.get("/use").expect(200, done)
    })

    it("Request delete", function (done) {
        app.delete("/delete", function (req, res) {
            res.send("ok")
        })

        supertest.delete("/delete").expect(200, done)
    })

    it("Kills the server", function (done) {
        app.events.once("kill", done)
        app.kill()
    })

    it("Restart the server", function (done) {
        let killer = function () {
            app.start()
            done()
        }

        app.events.on("start", killer)
        app.start()
    })
})
