// TEST: UTILS

require("coffeescript/register")
var env = process.env
var chai = require("chai")
var fs = require("fs")
chai.should()

describe("Utils System Tests", function() {
    env.NODE_ENV = "test"
    process.setMaxListeners(20)

    var settings = require("../lib/settings.coffee")
    var utils = require("../lib/utils.coffee")

    it("Get valid server info", function(done) {
        var serverInfo = utils.system.getInfo()

        if (serverInfo.cpuCores > 0) {
            done()
        } else {
            done("Could not get CPU core count from server info result.")
        }
    })
})
