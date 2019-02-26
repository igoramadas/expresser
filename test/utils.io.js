// TEST: UTILS

var env = process.env
var fs = require("fs")
var chai = require("chai")
var mocha = require("mocha")
var describe = mocha.describe
var before = mocha.before
var after = mocha.after
var it = mocha.it
chai.should()

describe("Utils IO Tests", function() {
    env.NODE_ENV = "test"
    process.setMaxListeners(20)

    var settings = require("../lib/settings.coffee")
    var utils = require("../lib/utils.coffee")

    var recursiveTarget = __dirname + "/mkdir/directory/inside/another"

    var cleanup = function() {
        if (fs.existsSync(recursiveTarget)) {
            fs.rmdirSync(__dirname + "/mkdir/directory/inside/another")
            fs.rmdirSync(__dirname + "/mkdir/directory/inside")
            fs.rmdirSync(__dirname + "/mkdir/directory")
            fs.rmdirSync(__dirname + "/mkdir")
        }
    }

    before(function() {
        cleanup()
    })

    after(function() {
        cleanup()
    })

    it("Creates directory recursively", function(done) {
        this.timeout = 5000

        var checkDir = function() {
            var stat = fs.statSync(recursiveTarget)

            if (stat.isDirectory()) {
                done()
            } else {
                done("Folder " + recursiveTarget + " was not created.")
            }
        }

        utils.io.mkdirRecursive(recursiveTarget)

        setTimeout(checkDir, 1000)
    })
})
