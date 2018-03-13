// TEST: MAILER

require("coffeescript/register")
var env = process.env
var chai = require("chai")
chai.should()

describe("Mailer Tests", function() {
    env.NODE_ENV = "test"
    process.setMaxListeners(20)

    var hasEnv = env["SMTP_USER"] ? true : false

    var settings = require("../lib/settings.coffee")
    var utils = null
    var mailer = null

    before(function() {
        settings.loadFromJson("../plugins/mailer/settings.default.json")
        settings.loadFromJson("settings.test.json")

        if (env["SMTP_USER"]) {
            settings.mailer.smtp.user = env["SMTP_USER"]
        }

        if (env["SMTP_PASSWORD"]) {
            settings.mailer.smtp.password = env["SMTP_PASSWORD"]
        }

        utils = require("../lib/utils.coffee")

        mailer = require("../plugins/mailer/index.coffee")
        mailer.expresser = require("../lib/index.coffee")
        mailer.expresser.events = require("../lib/events.coffee")
        mailer.expresser.logger = require("../lib/logger.coffee")
    })

    it("Has settings defined", function() {
        settings.should.have.property("mailer")
    })

    it("Inits", function() {
        mailer.init()
    })

    it("Load and process an email template", function(done) {
        var template = mailer.templates.get("test")
        var keywords = {
            name: "Joe Lee",
            email: "joelee@somemail.com"
        }

        var result = mailer.templates.parse(template, keywords)

        if (result.indexOf("test template") > 0 && result.indexOf(keywords.name) > 0 && result.indexOf(keywords.email) > 0) {
            done()
        } else {
            done("Unexpected template result: " + result)
        }
    })

    it("Clears the template cache", function() {
        mailer.templates.clearCache()
    })

    if (hasEnv) {
        it("Sends a template test email using Mailgun (SMTP)", async function() {
            this.timeout(12000)

            var smtp = mailer.createSmtp(settings.mailer.smtp)

            var msgOptions = {
                smtp: smtp,
                body: "SMTP testing: app {appTitle}, to {to}, using Mailgun.",
                subject: "Test mail",
                to: "Expresser <expresser@mailinator.com>",
                from: "devv@devv.com",
                template: "test",
                keywords: {
                    name: "Joe Lee",
                    email: "joelee@somemail.com"
                }
            }

            return await mailer.send(msgOptions)
        })

        it("Dummy send an email (doNotSend option is true)", async function() {
            settings.mailer.doNotSend = true

            var smtp = mailer.createSmtp(settings.mailer.smtp)

            var msgOptions = {
                smtp: smtp,
                body: "Dummy sending.",
                subject: "Test mail",
                to: ["expresser@mailinator.com"],
                from: "devv@devv.com"
            }

            return await mailer.send(msgOptions)
        })
    }

    it("Try sending email without a valid to address", async function() {
        var msgOptions = {
            body: "This should faild.",
            subject: "Test mail to fail",
            from: "devv@devv.com"
        }

        try {
            var result = await mailer.send(msgOptions)
            return new Error("Did not trigger error trying to send email with empty 'to'.")
        } catch (ex) {
            return true
        }
    })

    it("Try sending an email with no SMTP server defined", async function() {
        mailer.smtp = null
        mailer.smtp2 = null

        var msgOptions = {
            body: "This should faild.",
            subject: "Test mail to fail",
            to: "expresser@mailinator.com",
            from: "devv@devv.com"
        }

        try {
            var result = await mailer.send(msgOptions)
            return new Error("Did not trigger error trying to send email with invalid 'smtp'.")
        } catch (ex) {
            return true
        }
    })
})
