// TEST: SETTINGS

require("coffeescript/register")
var env = process.env
var chai = require("chai")
chai.should()

describe("Settings Tests", function() {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test"

    var settings = require("../lib/settings.coffee").newInstance()
    var fs = require("fs")
    var utils = null

    before(function() {
        settings.loadFromJson("settings.test.json")

        utils = require("../lib/utils.coffee")
    })

    it("Settings file watchers properly working", function(done) {
        this.timeout(10000)

        var doneCalled = false
        var filename = "./settings.test.json"
        var originalJson = fs.readFileSync(filename, {
            encoding: "utf8"
        })

        var newJson = utils.data.minifyJson(originalJson)

        var callback = function() {
            if (doneCalled) return
            doneCalled = true

            unwatch()

            fs.writeFileSync(filename, originalJson, {
                encoding: "utf8"
            })

            done()
        }

        var unwatch = function() {
            settings.watch(false, callback)
        }

        settings.watch(true, callback)
        newJson.testingFileWatcher = true

        var writer = function() {
            try {
                fs.writeFileSync(filename, JSON.stringify(newJson, null, 4))
            } catch (ex) {
                if (doneCalled) return
                doneCalled = true

                unwatch()
                done(ex)
            }
        }

        setTimeout(writer, 500)
    })

    it("Encrypt and decrypt settings data", function(done) {
        this.timeout(10000)

        var filename = "./settings.test.crypt.json"
        if (process.versions.node.indexOf(".10.") > 0) {
            var originalJson = fs.readFileSync(filename, {
                encoding: "utf8"
            })
        } else {
            var originalJson = fs.readFileSync(filename, "utf8")
        }

        var callback = function(err) {
            if (err) done(err)
            else done()
        }

        if (!settings.encrypt(filename)) {
            return callback("Could not encrypt properties of settings.test.json file.")
        }

        var encrypted = JSON.parse(
            fs.readFileSync(filename, {
                encoding: "utf8"
            })
        )

        if (!encrypted.encrypted) {
            return callback("Property 'encrypted' was not properly set.")
        } else if (encrypted.app.title == "Expresser Settings Encryption") {
            return callback("Encryption failed, settings.app.title is still set as 'Expresser'.")
        }

        settings.decrypt(filename)

        var decrypted = JSON.parse(
            fs.readFileSync(filename, {
                encoding: "utf8"
            })
        )

        if (decrypted.encrypted) {
            return callback("Property 'encrypted' was not unset / deleted.")
        }
        if (decrypted.app.title != "Expresser Settings Encryption") {
            return callback("Decryption failed, settings.app.title is still encrypted.")
        }

        callback()
    })
})
