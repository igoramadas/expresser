// TEST: LEGACY

let env = process.env
let chai = require("chai")
let mocha = require("mocha")
let moment = require("moment")
let after = mocha.after
let before = mocha.before
let describe = mocha.describe
let it = mocha.it

chai.should()

describe("App Legacy Tests", function() {
    let _ = require("lodash")
    let expresser
    let legacy
    let logger
    let settings
    let app, aws, cron, mailer, swagger

    before(async function() {
        require("setmeup").load()

        logger = require("anyhow")
        logger.setup("none")

        legacy = require("../plugins/legacy/index.js")
        expresser = require("../lib/index")
        app = expresser.app
    })

    after(function() {
        if (expresser && app && app.kill) {
            app.kill()
        }
    })

    it("Init the legacy module with plugins and settings", function(done) {
        legacy.init(expresser)
        expresser.setmeup.load(__dirname + "/testsettings.json")

        settings = expresser.settings
        settings.logger.removeFields = ["username"]

        if (expresser.plugins.length == 0) {
            done("No plugins were loaded.")
        } else if (!expresser.settings.aws.enabled) {
            done("Plugin settings for AWS not loaded.")
        }

        done()
    })

    it("Legacy expresser-aws basic tests", async function() {
        this.timeout(10000)

        if (!env["AWS_ACCESS_KEY_ID"] || !env["AWS_SECRET_ACCESS_KEY"]) {
            throw new Error("AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY not defined.")
        }

        aws = expresser.plugins.aws

        uploadTimestamp = moment().unix()

        var contents = {
            timestamp: uploadTimestamp
        }

        var options = {
            bucket: "expresser.devv.com",
            key: "test-" + uploadTimestamp + ".json",
            body: JSON.stringify(contents, null, 2)
        }

        return await aws.s3.upload(options)
    })

    it("Legacy expresser-cron basic tests", function(done) {
        cron = expresser.plugins.cron

        cron.load("test/testcron.json", {
            basePath: "../../../lib/",
            autoStart: false
        })

        cron.start()

        if (cron.jobs.length == 1) {
            cron.stop()
            done()
        } else {
            done("Cron should have exactly 1 job loaded from testcron.json.")
        }
    })

    it("Legacy expresser-mailer basic tests", async function() {
        this.timeout(10000)
        mailer = expresser.plugins.mailer

        if (env["EXP_SMTP_USER"]) {
            settings.mailer.smtp.user = env["EXP_SMTP_USER"]
        }

        if (env["EXP_SMTP_PASSWORD"]) {
            settings.mailer.smtp.password = env["EXP_SMTP_PASSWORD"]
        }

        let template = mailer.templates.get("test")
        let keywords = {
            name: "Joe Lee",
            email: "joelee@somemail.com"
        }

        let result = mailer.templates.parse(template, keywords)

        if (result.indexOf("test template") < 0 || result.indexOf(keywords.name) < 0) {
            throw new Error("Unexpected template result: " + result)
        }

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

    it("Legacy expresser-swagger basic tests", function(done) {
        this.timeout(10000)
        swagger = expresser.plugins.swagger

        let handlers = {
            getNumber: function(req, res) {
                res.json({
                    result: req.params.number
                })
            }
        }

        app.init()
        swagger.setup(handlers)

        let supertest = require("supertest").agent(app.expressApp)
        supertest.get("/swagger.json").expect(200, done)
    })
})
