// TEST: SETTINGS

require("coffeescript/register")
var env = process.env
var chai = require("chai")
chai.should()

describe("Settings Tests", function() {
    env.NODE_ENV = "test"
    process.setMaxListeners(20)

    var settings = require("../lib/settings.coffee").newInstance()
    var fs = require("fs")
    var utils = null

    var filename = "./settings.test.json"
    var cryptoFilename = "./settings.test.crypt.json"

    before(function() {
        settings.loadFromJson("settings.test.json")

        utils = require("../lib/utils.coffee")
    })

    after(function() {
        settings.unwatch()
    })

    it("Settings file watchers properly working", function(done) {
        this.timeout(10000)

        var doneCalled = false

        var originalJson = fs.readFileSync(filename, {
            encoding: "utf8"
        })

        delete originalJson.testingFileWatcher

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
            settings.unwatch(callback)
        }

        settings.watch(callback)
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

    it("Encrypt the settings file", function(done) {
        if (!settings.encrypt(cryptoFilename)) {
            return callback("Could not encrypt properties of settings.test.json file.")
        }

        var encrypted = JSON.parse(
            fs.readFileSync(cryptoFilename, {
                encoding: "utf8"
            })
        )

        if (!encrypted.encrypted) {
            return done("Property 'encrypted' was not properly set.")
        }
        if (encrypted.app.title == "Expresser Settings Encryption") {
            return done("Encryption failed, settings.app.title is still set as 'Expresser'.")
        }

        done()
    })

    it("Fails to decrypt settings with wrong key", function(done) {
        try {
            settings.decrypt(cryptoFilename, {
                key: "12345678901234561234567890123456"
            })

            done("Decryption with wrong key should have thrown an exception.")
        } catch (ex) {
            done()
        }
    })

    it("Decrypt the settings file", function(done) {
        try {
            settings.decrypt(cryptoFilename)

            var decrypted = JSON.parse(
                fs.readFileSync(cryptoFilename, {
                    encoding: "utf8"
                })
            )
        } catch (ex) {
            return done(ex.toString())
        }

        if (decrypted.encrypted) {
            return done("Property 'encrypted' was not unset / deleted.")
        }
        if (decrypted.app.title != "Expresser Settings Encryption") {
            return done("Decryption failed, settings.app.title is still encrypted.")
        }

        done()
    })
})
