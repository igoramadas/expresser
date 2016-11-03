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

    if (hasEnv) {
        it("Sends a test email", function (done) {
            this.timeout(20000);

            var msgOptions = {
                body: "Mail testing: app {appTitle}, to {to}.",
                subject: "Test mail",
                to: "expresser@mailinator.com",
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
    } else {
        it.skip("Sends a test email (skipped, no user or password set)");
    }
});