// TEST: MIDDLEWARES

import {after, before, describe, it} from "mocha"
require("chai").should()

describe("App Middleware Tests", function () {
    let app = null
    let setmeup = null
    let settings = null
    let supertest = null

    before(async function () {
        let port = 8004
        let logger = require("anyhow")
        logger.setup("none")

        app = require("../src/index").app.newInstance()
        setmeup = require("setmeup")
        settings = setmeup.settings
        settings.app.port = port
        settings.app.ssl.enabled = false
        settings.app.compression.enabled = true
        settings.app.cookie.enabled = true
        settings.app.session.enabled = true
        settings.app.viewPath = "./test/"
    })

    after(function () {
        if (app && app.kill) {
            app.kill()
        }
    })

    it("Init HTTP server with custom middlewares", function () {
        let prepend = function (req, res, next) {
            if (req.path == "/prepend") {
                res.json({
                    ok: true
                })
            }
            next()
        }

        let append = function (req, res, next) {
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

    it("Test prepended middleware on route /prepend", function (done) {
        supertest.get("/prepend").expect("Content-Type", /json/).expect(200, done)
    })

    it("Test appended middleware on route /append", function (done) {
        supertest.get("/append").expect("Content-Type", /json/).expect(200, done)
    })

    it("Set and read request session", function (done) {
        app.get("/setsession", function (req, res) {
            req.session.something = "ABC"
            app.renderJson(req, res, {
                session: true
            })
        })

        app.get("/getsession", function (req, res) {
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

        var setCallback = function (err) {
            if (err) {
                done(err)
            } else {
                var getSession = function () {
                    supertest.get("/getsession").expect(200, done)
                }
                setTimeout(getSession, 200)
            }
        }

        supertest.get("/setsession").expect(200, setCallback)
    })
})
