// TEST: VIEW

let chai = require("chai")
let getPort = require("get-port")
let mocha = require("mocha")
let after = mocha.after
let before = mocha.before
let describe = mocha.describe
let it = mocha.it

chai.should()

describe("App Logger Tests", function() {
    let logger
    let setmeup

    before(async function() {
        setmeup = require("setmeup")
        settings = setmeup.settings
        settings.logger.removeFields = ["username"]

        logger = require("anyhow")
        logger.setup("none")
        logger.preprocessor = require("../lib/logger").clean
    })

    it("General message args cleaning", function(done) {
        let innerObject = {
            more: {
                something: {
                    very: {
                        deep: {
                            inside: {
                                here: {
                                    one: {
                                        more: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        let func = function() {
            return true
        }

        let err = new Error("There was an error")
        let longArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, err, func, innerObject]

        logger.getMessage(null, {}, "A", 1, err, func, innerObject, longArray, [err, func, innerObject, longArray])

        done()
    })

    it("Maks fields (token and mobile)", function(done) {
        let toMask = {
            token: "ABC123",
            mobile: {
                value: "017612345678"
            }
        }

        let msg = logger.getMessage(toMask)

        if (msg.token == "ABC123" || msg.mobile == "017612345678") {
            done("The token and/or mobile were not properly masked.")
        } else {
            done()
        }
    })

    it("Obfuscate sensitive fields (password and accesstoken)", function(done) {
        let toObfuscate = {
            password: "mypassword",
            accesstoken: {
                value: "123"
            }
        }

        let msg = logger.getMessage(toObfuscate)

        if (msg.password == "mypassword" || msg.accesstoken) {
            done("The password and/or accesstoken were not obfuscated.")
        } else {
            done()
        }
    })

    it("Remove fields (username)", function(done) {
        let toRemove = {
            name: "John Doe",
            username: "jdoe"
        }

        let msg = logger.getMessage(toRemove)

        if (msg.username) {
            done("The username was not removed.")
        } else {
            done()
        }
    })
})
