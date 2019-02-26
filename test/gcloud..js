// TEST: GOOGLE CLOUD

var env = process.env
var chai = require("chai")
var mocha = require("mocha")
var describe = mocha.describe
var before = mocha.before
var it = mocha.it
chai.should()

describe("^Google Cloud Tests", function() {
    env.NODE_ENV = "test"
    process.setMaxListeners(20)

    var settings = require("../lib/settings.coffee")
    var fs = require("fs")
    var moment = require("moment")
    var gcloud = null

    before(function() {
        settings.loadFromJson("../plugins/gcloud/settings.default.json")
        settings.loadFromJson("settings.test.json")

        utils = require("../lib/utils.coffee")

        gcloud = require("../plugins/gcloud/index.coffee")
        gcloud.expresser = require("../lib/index.coffee")
        gcloud.expresser.events = require("../lib/events.coffee")
        gcloud.expresser.logger = require("../lib/logger.coffee")
    })

    it("Has settings defined", function() {
        settings.should.have.property("gcloud")
    })

    it("Inits", function() {
        gcloud.init()
    })
})
