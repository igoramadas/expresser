// TEST: MAIN

require("coffeescript/register")
var env = process.env
var chai = require("chai")
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
        global.asyncDump()
    })

    it("Inits", function() {
        expresser.init(false)
    })
})
