// TEST: MAILER

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Mailer Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var utils = null;
    var mailer = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function(){
        utils = require("../lib/utils.coffee");
        mailer = require("../lib/mailer.coffee");
    });

    it("Is single instance", function() {
        mailer.singleInstance = true;
        var mailer2 = require("../lib/mailer.coffee");
        mailer.singleInstance.should.equal(mailer2.singleInstance);
    });

    it("Has settings defined", function() {
        settings.should.have.property("mailer");
    });

    it("Inits", function() {
        mailer.init();
    });

    it("Sends a test email using Mandrill", function(done) {
        this.timeout(10000);

        if (!env.MDA) {
            return done(new Error("The 'MDA' variable which defines the Mandrill password was not set."));
        }

        var smtpOptions = {
            password: env.MDA,
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