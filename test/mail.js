// TEST: MAIL

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Mail Tests", function() {

    var mail = require("../lib/mail.coffee");
    var settings = require("../lib/settings.coffee");

    it("Is single instance.", function() {
        mail.singleInstance = true;
        var mail2 = require("../lib/mail.coffee");
        mail.singleInstance.should.equal(mail2.singleInstance);
    });

    it("Has settings defined.", function() {
        settings.should.have.property("mail");
    });

    it("Inits.", function() {
        mail.init();
    });
});