// TEST: AWS - SNS

var env = process.env
var chai = require("chai")
var mocha = require("mocha")
var describe = mocha.describe
var before = mocha.before
chai.should()

describe("AWS SNS Tests", function() {
    env.NODE_ENV = "test"
    process.setMaxListeners(20)

    var settings = require("../lib/settings.coffee")
    var fs = require("fs")
    var moment = require("moment")
    var aws = null
    var hasKeys = false
    var uploadTimestamp = 0

    if (env["AWS_ACCESS_KEY_ID"] || env["AWS_SECRET_ACCESS_KEY"] || env["AWS_CONFIGURED"]) {
        hasKeys = true
    }

    before(function() {
        settings.loadFromJson("../plugins/aws/settings.default.json")
        settings.loadFromJson("settings.test.json")

        utils = require("../lib/utils.coffee")

        aws = require("../plugins/aws/index.coffee")
        aws.expresser = require("../lib/index.coffee")
        aws.expresser.events = require("../lib/events.coffee")
        aws.expresser.logger = require("../lib/logger.coffee")

        aws.init()
    })
})
