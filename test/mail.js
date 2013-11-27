// TEST: MAIL

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Mail Tests", function() {
    var settings = require("../lib/settings.coffee");
    var utils = null;
    var mail = null;

    before(function() {
        utils = require("../lib/utils.coffee");
        utils.loadDefaultSettingsFromJson();

        settings.mail.from = "expresser@devv.com";
        settings.mail.smtp.host = "mandrill";
        utils.updateSettingsFromPaaS("mail");

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

    it("Sends a test email with custom keywords", function(done) {
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