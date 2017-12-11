// TEST: MAIN

require("coffeescript/register")
var env = process.env
var chai = require("chai")
chai.should()

describe("Expresser (Main) Tests", function() {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test"

    var expresser = require("../lib/index.coffee").newInstance()

    before(function() {
        expresser.settings.loadFromJson("settings.test.json")
    })

    it("Inits", function() {
        expresser.init()
    })
})
