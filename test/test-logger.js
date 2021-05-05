// TEST: LOGGER

let chai = require("chai")
let mocha = require("mocha")
let before = mocha.before
let describe = mocha.describe
let it = mocha.it

chai.should()

describe("App Logger Tests", function () {
    let logger
    let setmeup

    before(async function () {
        setmeup = require("setmeup")
        setmeup.load()
        settings = setmeup.settings
        settings.logger.removeFields = ["username"]

        logger = require("anyhow")
        logger.setup("none")
        logger.preprocessor = require("../lib/logger").clean
    })

    it("General message args cleaning", function (done) {
        let innerObject = {
            more: {
                something: {
                    very: {
                        deep: {
                            inside: true
                        }
                    }
                }
            },
            someString: "abcd",
            someNumber: 123,
            someError: new Error("Inner error"),
            someArray: [
                {
                    innerArray: []
                }
            ],
            someFunction: () => {
                return true
            }
        }

        let func = function () {
            return true
        }

        let err = new Error("There was an error")
        let longArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, "abc", true, false, err, func, innerObject]

        let msg = logger.getMessage(1, "A", new Date(), null, err, func, innerObject, longArray, [err, func, innerObject, longArray])

        try {
            if (innerObject.someFunction()) {
                return done()
            }

            return done("The innerObject.someFunction() should return true.")
        } catch (ex) {
            return done("The innerObject.someFunction() should still be a function, but was mutated by the Logger.")
        }
    })

    it("Maks fields (mobile)", function (done) {
        let msg = logger.getMessage({
            mobile: "123456789"
        })
        if (msg.indexOf("123456789") >= 0) {
            return done("The mobile was not obfuscated.")
        }

        msg = logger.getMessage({
            mobile: {
                value: "123456789"
            }
        })
        if (msg.indexOf("123456789") >= 0) {
            return done("The mobile (value) was not obfuscated.")
        }

        msg = logger.getMessage({
            mobile: {
                text: "123456789"
            }
        })
        if (msg.indexOf("123456789") >= 0) {
            return done("The mobile (text) was not obfuscated.")
        }

        msg = logger.getMessage({
            mobile: {
                data: "123456789"
            }
        })
        if (msg.indexOf("123456789") >= 0) {
            return done("The mobile (data) was not obfuscated.")
        }

        let obj = {}
        obj.toString = function () {
            return "123456789"
        }

        msg = logger.getMessage({
            mobile: obj
        })
        if (msg.indexOf("123456789") >= 0) {
            return done("The mobile (data) was not obfuscated.")
        }

        done()
    })

    it("Obfuscate sensitive fields (password and accesstoken)", function (done) {
        let msg = logger.getMessage({
            password: "mypassword"
        })
        if (msg.indexOf("mypassword") >= 0) {
            return done("The password was not obfuscated.")
        }
        done()
    })

    it("Remove fields (username)", function (done) {
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
