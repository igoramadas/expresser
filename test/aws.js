// TEST: AWS

require("coffeescript/register")
var env = process.env
var chai = require("chai")
chai.should()

describe("AWS Tests", function() {
    env.NODE_ENV = "test"
    process.setMaxListeners(20)

    var settings = require("../lib/settings.coffee")
    var fs = require("fs")
    var moment = require("moment")
    var aws = null
    var hasKeys = false

    before(function() {
        settings.loadFromJson("../plugins/aws/settings.default.json")
        settings.loadFromJson("settings.test.json")

        utils = require("../lib/utils.coffee")

        aws = require("../plugins/aws/index.coffee")
        aws.expresser = require("../lib/index.coffee")
        aws.expresser.events = require("../lib/events.coffee")
        aws.expresser.logger = require("../lib/logger.coffee")
    })

    it("Has settings defined", function() {
        settings.should.have.property("aws")
    })

    it("Inits", function() {
        aws.init()
    })
})
