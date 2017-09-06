// TEST: UTILS

require("coffeescript/register")
var env = process.env
var chai = require("chai")
var fs = require("fs")
chai.should()

describe("Utils IO Tests", function() {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test"

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
