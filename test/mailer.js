// TEST: MAILER

require("coffee-script/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("Mailer Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";
    var hasEnv = env["SMTP_USER"] ? true : false;

    var settings = require("../lib/settings.coffee");
    var utils = null;
    var mailer = null;

    before(function () {
        settings.loadFromJson("../plugins/mailer/settings.default.json");
        settings.loadFromJson("settings.test.json");

        if (env["SMTP_USER"]) {
            settings.mailer.smtp.user = env["SMTP_USER"];
        }

        if (env["SMTP_PASSWORD"]) {
            settings.mailer.smtp.password = env["SMTP_PASSWORD"];
        }

        if (env["SMTP2_USER"]) {
            settings.mailer.smtp2.user = env["SMTP2_USER"];
        }

        if (env["SMTP2_PASSWORD"]) {
            settings.mailer.smtp2.password = env["SMTP2_PASSWORD"];
        }

        utils = require("../lib/utils.coffee");

        mailer = require("../plugins/mailer/index.coffee");
        mailer.expresser = require("../index.coffee");
        mailer.expresser.events = require("../lib/events.coffee");
        mailer.expresser.logger = require("../lib/logger.coffee");
    });

    it("Has settings defined", function () {
        settings.should.have.property("mailer");
    });

    it("Inits", function () {
        mailer.init();
    });

    it("Load and process an email template", function (done) {
        var template = mailer.getTemplate("test");
        var keywords = {
            name: "Joe Lee",
            email: "joelee@somemail.com"
        };

        var result = mailer.parseTemplate(template, keywords);

        if (result.indexOf("test template") > 0 && result.indexOf(keywords.name) > 0 && result.indexOf(keywords.email) > 0) {
            done()
        } else {
            done("Unexpected template result: " + result);
        }
    });

    it("Clears the template cache", function () {
        mailer.clearCache();
    });

    if (hasEnv) {
        it("Sends a template test email using Mailgun (SMTP)", function (done) {
            this.timeout(12000);

            var smtp = mailer.createSmtp(settings.mailer.smtp);

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
            };

            var callback = function (err) {
                if (!err) {
                    done();
                } else {
                    done(err);
                }
            };

            mailer.send(msgOptions, callback);
        });

        it("Sends a test email using Debug Mail (SMTP2)", function (done) {
            this.timeout(12000);

            var smtp = mailer.createSmtp(settings.mailer.smtp2);

            var msgOptions = {
                smtp: smtp,
                body: "SMTP2 testing: app {appTitle}, to {to}, using Debug Mail.",
                subject: "Test mail",
                to: ["expresser@mailinator.com", "expresser-mailer@mailinator.com"],
                from: "devv@devv.com"
            };

            var callback = function (err) {
                if (!err) {
                    done();
                } else {
                    done(err);
                }
            };

            mailer.send(msgOptions, callback);
        });

        it("Dummy send an email (doNotSend option is true)", function (done) {
            settings.mailer.doNotSend = true;

            var smtp = mailer.createSmtp(settings.mailer.smtp2);

            var msgOptions = {
                smtp: smtp,
                body: "Dummy sending.",
                subject: "Test mail",
                to: ["expresser@mailinator.com"],
                from: "devv@devv.com"
            };

            var callback = function (err, result) {
                settings.mailer.doNotSend = false;

                if (!err && result.indexOf("doNotSend") > 0) {
                    done();
                } else {
                    done("Result of mailer.send should return a message having 'doNotSend'.");
                }
            };

            mailer.send(msgOptions, callback);
        });
    } else {
        it.skip("Sends a test email (skipped, no user or password set)");
    }

    it("Try sending email without a valid to address", function (done) {
        var msgOptions = {
            body: "This should faild.",
            subject: "Test mail to fail",
            from: "devv@devv.com"
        };

        try {
            mailer.send(msgOptions);
            done("Sending should throw and error and fail!");
        } catch (ex) {
            done();
        }
    });

    it("Try sending an email with no SMTP server defined", function (done) {
        mailer.smtp = null;
        mailer.smtp2 = null;

        var msgOptions = {
            body: "This should faild.",
            subject: "Test mail to fail",
            to: "expresser@mailinator.com",
            from: "devv@devv.com"
        };

        try {
            mailer.send(msgOptions);
            done("Sending should throw and error and fail!");
        } catch (ex) {
            done();
        }
    });
});
