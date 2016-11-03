// TEST: PAAS

require("coffee-script/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("PaaS Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var app = null;
    var database = null;
    var logger = null;
    var mailer = null;
    var paas = null;

    before(function () {
        settings.loadFromJson("../plugins/paas/settings.default.json");
        settings.loadFromJson("settings.test.json");
        settings.app.port = 18118;

        app = require("../lib/app.coffee").newInstance();

        database = require("../lib/database.coffee").newInstance();

        logger = require("../lib/logger.coffee").newInstance();

        mailer = require("../plugins/mailer/index.coffee");
        mailer.expresser = require("../index.coffee");
        mailer.expresser.events = require("../lib/events.coffee");
        mailer.expresser.logger = require("../lib/logger.coffee");

        paas = require("../plugins/paas/index.coffee");
    });

    it("Has settings defined", function () {
        settings.should.have.property("paas");
    });

    it("Inits", function () {
        paas.init();
    });

    it("Updates app settings", function () {
        env.OPENSHIFT_NODEJS_IP = "127.0.0.1";

        app.init();

        env.OPENSHIFT_NODEJS_IP = null;
    });

    it("Updates database settings", function () {
        env.MONGOLAB_URI = "127.0.0.1/mongo-test";

        database.init();

        env.MONGOLAB_URI = null;
    });

    it("Updates logger settings", function () {
        env.LOGGLY_SUBDOMAIN = "logger-test";

        logger.init();

        env.LOGGLY_SUBDOMAIN = null;
    });

    it("Updates mailer settings", function () {
        env.MAILGUN_SMTP_LOGIN = "mailer-test";

        mailer.init();

        env.MAILGUN_SMTP_LOGIN = null;
    });
});