// TEST: MAIL

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Mail Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var utils = null;
    var mail = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function(){
        utils = require("../lib/utils.coffee");
        mail = require("../lib/mail.coffee");
    });

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

    it("Sends a test email using Mandrill", function(done) {
        this.timeout(10000);

        if (!env.MDA) {
            return done("The 'MDA' variable which defines the Mandrill password was not set.");
        }

        var smtpOptions = {
            password: env.MDA,
            host: "smtp.mandrillapp.com",
            port: 587,
            secure: false
        };

        var msgOptions = {
            body: "Mail testing: app {appTitle}, to {to}.",
            subject: "Test mail",
            to: settings.mail.from
        };

        var callback = function(err) {
            if (!err) {
                done();
            } else {
                done(err);
            }
        };

        mail.setSmtp(smtpOptions);
        mail.send(msgOptions, callback);
    });
});