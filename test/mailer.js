// TEST: MAILER

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Mailer Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("../plugins/mailer/settings.default.json");
    settings.loadFromJson("settings.test.json");
    settings.loadFromJson("settings.test.keys.json");

    var utils = null;
    var mailer = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function(){
        utils = require("../lib/utils.coffee");
        mailer = require("../plugins/mailer/index.coffee");
        mailer.expresser = require("../index.coffee");
        mailer.expresser.events = require("../lib/events.coffee");
        mailer.expresser.logger = require("../lib/logger.coffee");
    });

    it("Has settings defined", function() {
        settings.should.have.property("mailer");
    });

    it("Inits", function() {
        mailer.init();
    });

    it("Sends a test email using Mandrill", function(done) {
        this.timeout(20000);

        if (!settings.mailer.smtp.password) {
            return done(new Error("The mailer SMTP password was not set (settings.mailer.smtp.password)."));
        }

        var smtpOptions = {
            password: settings.mailer.smtp.password,
            user: "devv@devv.com",
            service: "mandrill"
        };

        var msgOptions = {
            body: "Mail testing: app {appTitle}, to {to}.",
            subject: "Test mail",
            to: "devv@devv.com",
            from: "devv@devv.com"
        };

        var callback = function(err) {
            if (!err) {
                done();
            } else {
                done(err);
            }
        };

        mailer.setSmtp(smtpOptions);
        mailer.send(msgOptions, callback);
    });
});
