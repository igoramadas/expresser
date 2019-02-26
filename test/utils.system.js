// TEST: UTILS

var env = process.env
var chai = require("chai")
var mocha = require("mocha")
var describe = mocha.describe
var it = mocha.it
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

    it("Get server info without labels", function(done) {
        var serverInfo = utils.system.getInfo({
            labels: false
        })

        if (serverInfo.memoryUsage.toString().indexOf("%") > 0 || serverInfo.memoryTotal.toString().indexOf("MB") > 0) {
            done("Output should not include labels % MB etc.")
        } else {
            done()
        }
    })
})
