// TEST: EVENTS

require("coffeescript/register")
var env = process.env
var chai = require("chai")
chai.should()

describe("Cron Tests", function() {
    env.NODE_ENV = "test"
    process.setMaxListeners(20)

    var settings = require("../lib/settings.coffee")
    var events = null

    before(function() {
        settings.loadFromJson("settings.test.json")

        events = require("../lib/events.coffee")
    })

    after(function() {
        events.off("Test.addListener")
        events.off("Test.addRemoveListener")
    })

    it("Emit a test event", function(done) {
        var listener = function(someString) {
            if (someString == "test123") {
                done()
            } else {
                done("The value passed should be 'test123', and we've got '" + someString + "'.")
            }
        }

        events.on("Test.addListener", listener)
        events.emit("Test.addListener", "test123")
    })

    it("Add and remove a listener", function(done) {
        var listener = function() {
            done("Listener was not removed.")
        }

        events.on("Test.addRemoveListener", listener)
        events.off("Test.addRemoveListener", listener)
        events.emit("Test.addRemoveListener", true)

        var timer = function() {
            done()
        }

        setTimeout(timer, 500)
    })
})
