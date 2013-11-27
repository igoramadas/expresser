// TEST: MAIL

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Mail Tests", function() {
    process.env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var utils = null;
    var mail = null;

    before(function() {
        utils = require("../lib/utils.coffee");
        utils.loadDefaultSettingsFromJson();

        mail = require("../lib/mail.coffee");

        settings.mail.
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

    it("Sends a test email with custom keywords.", function(done) {
        var options = {
            message: "Expresser mail to {to}.",
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