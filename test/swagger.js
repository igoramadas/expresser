// TEST: SWAGGER

var env = process.env
var chai = require("chai")
var mocha = require("mocha")
var describe = mocha.describe
var before = mocha.before
var after = mocha.after
var it = mocha.it
chai.should()

describe("Swagger Tests", function() {
    env.NODE_ENV = "test"
    process.setMaxListeners(20)

    var http = require("http")
    http.globalAgent.maxSockets = 20

    var settings = require("../lib/settings.coffee")
    var app = null
    var supertest = null
    var swagger = null

    before(function() {
        settings.loadFromJson("../plugins/swagger/settings.default.json")
        settings.loadFromJson("settings.test.json")

        settings.app.port = 18014
        settings.app.ssl.enabled = false

        app = require("../lib/app.coffee").newInstance()

        swagger = require("../plugins/swagger/index.coffee")
        swagger.expresser = require("../lib/index.coffee")
        swagger.expresser.app = app
        swagger.expresser.errors = require("../lib/errors.coffee")
        swagger.expresser.events = require("../lib/events.coffee")
        swagger.expresser.logger = require("../lib/logger.coffee")
        swagger.expresser.utils = require("../lib/utils.coffee")
    })

    after(function() {
        app.kill()
    })

    it("Inits", function() {
        swagger.init()
    })

    it("Has app settings defined", function() {
        settings.should.have.property("swagger")
    })

    it("Setup swagger routes", function() {
        this.timeout(10000)

        var handlers = {
            getNumber: function(req, res) {
                res.json({
                    result: req.params.number
                })
            }
        }

        app.init()
        swagger.setup(handlers)

        supertest = require("supertest").agent(app.expressApp)
    })

    it("Get Swagger specs", function(done) {
        this.timeout(5000)

        supertest.get("/swagger.json").expect(200, done)
    })

    it("Test API getNumber", function(done) {
        this.timeout(5000)

        supertest.get("/api/getnumber/10").expect(200, done)
    })
})
