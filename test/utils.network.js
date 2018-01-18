// TEST: UTILS

require("coffeescript/register")
var env = process.env
var chai = require("chai")
var fs = require("fs")
chai.should()

describe("Utils Network Tests", function() {
    env.NODE_ENV = "test"
    process.setMaxListeners(20)

    var settings = require("../lib/settings.coffee")
    var utils = require("../lib/utils.coffee")

    it("Check IP against multiple ranges", function(done) {
        var ip = "192.168.1.1"
        var validIP = "192.168.1.1"
        var validRange = "192.168.1.0/24"
        var validRangeArray = ["192.168.1.0/24", "192.168.0.0/16"]
        var invalidRange = "10.1.1.0/16"

        if (!utils.network.ipInRange(ip, validIP)) {
            done("IP " + ip + " should be valid against " + validIP + ".")
        } else if (!utils.network.ipInRange(ip, validRange)) {
            done("IP " + ip + " should be valid against " + validRange + ".")
        } else if (!utils.network.ipInRange(ip, validRangeArray)) {
            done("IP " + ip + " should be valid against " + validRangeArray.join(", ") + ".")
        } else if (!utils.network.ipInRange(ip, validIP)) {
            done("IP " + ip + " should be invalid against " + invalidRange + ".")
        } else {
            done()
        }
    })
})
