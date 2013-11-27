// TEST: MAIL

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Mail Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var utils = require("../lib/utils.coffee");
    var mail = null;
    var mandrill_it = null;

    utils.loadDefaultSettingsFromJson();
    utils.updateSettingsFromPaaS("mail");

    // Check for MDA (Mandrill) variable on Travis.
    if (env.MDA) {
        settings.mail.smtp.password = env.MDA;
    }

    // Decide if Mandrill should be tested.
    if (settings.mail.smtp.host.indexOf("mandrill") >= 0 && settings.mail.smtp.password) {
        mandrill_it = it;
    } else {
        mandrill_it = it.skip;
    }

    mail = require("../lib/mail.coffee");

    it("Is single instance", function() {
        mail.singleInstance = true;
        var mail2 = require("../lib/mail.coffee");
        mail.singleInstance.should.equal(mail2.singleInstance);
    });

    it("Has settings defined", function() {
        settings.should.have.property("mail");
    });

    it("Inits", function() {
        mail.init();
    });

    mandrill_it("Sends a test email using Mandrill", function(done) {
        this.timeout(10000);

        var options = {
            body: "Mail testing: app {appTitle}, to {to}.",
            subject: "Test mail",
            to: settings.mail.from
        };

        var callback = function(err, result) {
            if (!err) {
                done();
            } else {
                done(err);
            }
        };

        mail.send(options, callback);
    });
});