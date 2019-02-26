// TEST: KILL AND CLEANUP

var env = process.env
var chai = require("chai")
var mocha = require("mocha")
var describe = mocha.describe
var before = mocha.before
var after = mocha.after
var it = mocha.it
chai.should()

describe("Expresser (Main) Tests", function() {
    env.NODE_ENV = "test"
    process.setMaxListeners(20)

    var expresser = require("../lib/index.coffee").newInstance()

    before(function() {
        expresser.settings.loadFromJson("settings.test.json")
    })

    after(function() {
        expresser.app.kill()

        var quit = function() {
            process.exit()
        }

        setTimeout(quit, 3000)
    })

    it("Inits", function() {
        expresser.init(false)
    })
})
