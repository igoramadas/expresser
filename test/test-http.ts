// TEST: HTTP

import {after, before, describe, it} from "mocha"
require("chai").should()

describe("App HTTP Tests", function () {
    let app = null
    let setmeup = null
    let settings = null
    let supertest = null

    before(async function () {
        let port = 8002

        app = require("../src/index").app.newInstance()
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

    it("Binds a callback once", function () {
        let count = 0

        app.once("once-test", () => {
            count++
        })
        app.events.emit("once-test")
        app.events.emit("once-test")

        if (count !== 1) {
            throw new Error("once listener ran " + count + " times")
        }
    })

    it("Request set property", function () {
        app.set("trust proxy", 1)

        if (app.get("trust proxy") !== 1) {
            throw new Error("app.get did not read the Express setting")
        }
    })

    it("Request all", function (done) {
        app.get("/all", function (req: Request, res) {
            res.send(req.body)
        })

        supertest.get("/all").expect(200, done)
    })

    it("Request get", function (done) {
        app.get("/get", function (req: Request, res) {
            res.send(req.body)
        })

        supertest.get("/get").expect(200, done)
    })

    it("Request post json", function (done) {
        app.post("/post-json", function (req: Request, res) {
            res.send(req.body)

            if (req.body && req.body["hello"] == 123) {
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
        app.patch("/patch", function (req: Request, res) {
            res.send(req.body)
        })

        supertest.patch("/patch").expect(200, done)
    })

    it("Request put", function (done) {
        app.put("/put", function (req: Request, res) {
            res.send(req.body)
        })

        supertest.put("/put").expect(200, done)
    })

    it("Request use", function (done) {
        app.use("/use", function (req: Request, res) {
            res.send(req.body)
        })

        supertest.get("/use").expect(200, done)
    })

    it("Request delete", function (done) {
        app.delete("/delete", function (req: Request, res) {
            res.send(req.body)
        })

        supertest.delete("/delete").expect(200, done)
    })

    it("Registers a single route", function (done) {
        app.route("/routed/:id").get((req, res) => {
            res.send(req.params.id)
        })

        supertest.get("/routed/42").expect(200, "42", done)
    })

    it("Runs param callbacks for routes added after init", function (done) {
        app.expressApp.param("id", (req, _res, next, id) => {
            req.params.loaded = id
            next()
        })
        app.get("/params/:id", (req, res) => {
            res.send(req.params.loaded)
        })

        supertest.get("/params/42").expect(200, "42", done)
    })

    it("Returns the Express app from route shortcuts", function () {
        const chained = app.get("/chain", (_req, res) => res.send("ok"))

        if (typeof chained.set != "function" || typeof chained.disable != "function") {
            throw new Error("Route shortcut did not return the Express app")
        }

        chained.set("title", "Expresser")
    })

    it("Mounts a child Express app", function (done) {
        const express = require("express")
        const child = express()
        let parentAfter = null

        child.use((_req, res, next) => {
            res.send("child")
            next()
        })
        app.use("/child", child)
        app.use((req, _res, next) => {
            if (req.path == "/child") {
                parentAfter = req.app
            }
            next()
        })

        if (child.parent != app.expressApp || child.mountpath != "/child") {
            return done(new Error("Child app was not mounted on the Express app"))
        }

        supertest
            .get("/child")
            .expect(200, "child")
            .end((err) => {
                if (err) {
                    return done(err)
                }
                if (parentAfter != app.expressApp) {
                    return done(new Error("Parent app was not restored after the child app"))
                }

                done()
            })
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
