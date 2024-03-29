// TEST: ROUTES

import {after, before, describe, it} from "mocha"
require("chai").should()

describe("App Routes Tests", function () {
    let app = null
    let routes = null
    let setmeup = null
    let settings = null
    let supertest = null

    let handlers = {
        getDefault: (req, res) => {
            res.send(req.body)
        },
        getAbc: (req, res) => {
            res.send(req.body)
        },
        postAbc: (req, res) => {
            res.send(req.body)
        },
        getDef: (req, res) => {
            res.send(req.body)
        },
        getSwaggerAbc: (req, res) => {
            res.json({ok: req.body})
        }
    }

    let sampleSpecs = {
        "/from-specs": "getDefault"
    }

    let sampleSwaggerSpecs = {
        info: {
            title: "Sample Swagger"
        },
        paths: {
            "/from-swagger-specs": {
                get: {
                    operationId: "getDefault"
                }
            }
        }
    }

    before(async function () {
        let port = 8008
        let logger = require("anyhow")
        logger.setup("none")

        app = require("../src/index").app
        routes = require("../src/index").routes
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

    after(function () {
        if (app && app.kill) {
            app.kill()
        }
    })

    it("Has settings defined", function () {
        settings.should.have.property("routes")
    })

    it("Load routes from default file", function (done) {
        routes.load({handlers: handlers})

        supertest.get("/").expect(200)
        supertest.get("/abc").expect(200)
        supertest.post("/abc").expect(200, done)
    })

    it("Pass routes directly via options.specs", function (done) {
        routes.load({handlers: handlers, specs: sampleSpecs})

        supertest.get("/from-specs").expect(200, done)
    })

    it("Fails to load routes from incorrect files", function (done) {
        try {
            routes.load({filename: "notexisting.json", handlers: handlers})
            done("Calling load with non existing file should have failed.")
        } catch (ex) {}

        try {
            routes.load({filename: "./test/testview.pug", handlers: handlers})
            done("Calling load passing an invalid JSON file should have failed.")
        } catch (ex) {
            done()
        }
    })

    it("Fails to load routes with missing handlers", function (done) {
        try {
            routes.load()
            done("Calling load without passing handles should have failed.")
        } catch (ex) {}

        try {
            routes.load(true)
            done("Calling load without passing handles should have failed.")
        } catch (ex) {}

        try {
            sampleSpecs["/from-specs-invalid"] = "lalala"
            routes.load({handlers: handlers, specs: sampleSpecs})
            done("Should have failed to load with invalid lalala handler")
        } catch (ex) {}

        try {
            sampleSpecs["/from-specs-invalid"] = {invalidMethod: "lalala"}
            routes.load({handlers: handlers, specs: sampleSpecs})
            done("Should have failed to load with invalid method")
        } catch (ex) {
            done()
        }
    })

    it("Load swagger from default file", function (done) {
        routes.loadSwagger({handlers: handlers})

        supertest.get("/swagger/abc").expect(200)
        supertest.get("/swagger/abc?qs=string&qnum=1&qbool=true&qnum=5&qint=7&qdate=2010-01-01&qcsv=a,1,2&qpipes=a|1&qssv=z&&qsep=lala,lala").expect(200, done)
    })

    it("Pass swagger directly via options.specs, with version, and exposing as swagger.json", function (done) {
        settings.routes.swagger.exposeJson = true

        routes.loadSwagger({
            handlers: handlers,
            specs: sampleSwaggerSpecs,
            version: "1.0.0"
        })

        supertest.get("/from-swagger-specs").expect(200, done)
    })

    it("Fails to load swagger from incorrect files", function (done) {
        try {
            routes.loadSwagger({filename: "notexisting.json", handlers: handlers})
            done("Calling loadSwagger with non existing file should have failed.")
        } catch (ex) {}

        try {
            routes.loadSwagger({filename: "./test/testview.pug", handlers: handlers})
            done("Calling loadSwagger passing an invalid JSON file should have failed.")
        } catch (ex) {
            done()
        }
    })

    it("Fails to load swagger with missing path specs", function (done) {
        try {
            let invalidSwagger = {
                paths: {
                    "/missing-method": null
                }
            }

            routes.loadSwagger({handlers: handlers, specs: invalidSwagger})
            done("Loading invalid swagger with missing method spec should have failed.")
        } catch (ex) {
            done()
        }
    })

    it("Fails to load swagger with missing handlers", function (done) {
        try {
            routes.loadSwagger()
            done("Calling loadSwagger without passing handles should have failed.")
        } catch (ex) {}

        try {
            routes.loadSwagger(true)
            done("Calling loadSwagger without passing handles should have failed.")
        } catch (ex) {}

        try {
            sampleSwaggerSpecs.paths["/from-specs-invalid"] = {
                get: {
                    operationId: "lalala"
                }
            }
            routes.loadSwagger({handlers: handlers, specs: sampleSwaggerSpecs})
            done("Should have failed to load swagger with invalid lalala handler")
        } catch (ex) {}

        try {
            sampleSwaggerSpecs.paths["/from-specs-invalid"] = {
                wrongMethod: {
                    operationId: "lalala"
                }
            }
            routes.loadSwagger({handlers: handlers, specs: sampleSwaggerSpecs})
            done("Should have failed to load swagger with invalid method")
        } catch (ex) {}

        try {
            sampleSwaggerSpecs.paths["/from-specs-invalid"] = {
                get: null
            }
            routes.loadSwagger({handlers: handlers, specs: sampleSwaggerSpecs})
            done("Should have failed to load swagger with invalid method")
        } catch (ex) {
            done()
        }
    })

    it("Casting invalid parameters", function (done) {
        supertest.get("/swagger/abc?qnum=zzz&&qdate=zzz&qbool= ").expect(200, done)
    })
})
