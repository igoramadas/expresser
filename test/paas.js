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
    var loggerLoggly = null;
    var mailer = null;
    var paas = null;

    before(function () {
        settings.loadFromJson("../plugins/logger-loggly/settings.default.json");
        settings.loadFromJson("../plugins/mailer/settings.default.json");
        settings.loadFromJson("../plugins/paas/settings.default.json");
        settings.loadFromJson("settings.test.json");
        settings.app.port = 18118;
        settings.mailer.smtp.host = "mailgun"

        app = require("../lib/app.coffee").newInstance();

        database = require("../lib/database.coffee").newInstance();

        logger = require("../lib/logger.coffee").newInstance();

        loggerLoggly = require("../plugins/logger-loggly/index.coffee");
        loggerLoggly.expresser = require("../index.coffee");
        loggerLoggly.expresser.events = require("../lib/events.coffee");
        loggerLoggly.expresser.logger = require("../lib/logger.coffee");

        mailer = require("../plugins/mailer/index.coffee");
        mailer.expresser = require("../index.coffee");
        mailer.expresser.events = require("../lib/events.coffee");
        mailer.expresser.logger = require("../lib/logger.coffee");

        paas = require("../plugins/paas/index.coffee");
        paas.expresser = require("../index.coffee");
        paas.expresser.events = require("../lib/events.coffee");
        paas.expresser.logger = require("../lib/logger.coffee");
    });

    it("Has settings defined", function () {
        settings.should.have.property("paas");
    });

    it("Inits", function () {
        paas.init();
    });

    it("Updates app settings", function (done) {
        var err;
        var ip = "127.0.0.1";

        env.OPENSHIFT_NODEJS_IP = ip;
        app.init();

        if (settings.app.ip != "127.0.0.1") {
            err = "App IP not updated. Expected '" + ip + "', got '" + settings.app.ip + "'.";
        }

        env.OPENSHIFT_NODEJS_IP = null;
        app.kill();
        done(err);
    });

    it("Updates database settings", function (done) {
        var err;
        var connString = "127.0.0.1/mongo-test";

        env.MONGOLAB_URI = connString;
        database.init();

        if (settings.database.mongodb.connString != connString) {
            err = "Database connection string not updated. Expected '" + connString + "', got '" + settings.database.mongodb.connString + "'.";
        }

        env.MONGOLAB_URI = null;
        done(err);
    });

    it("Updates logger settings", function (done) {
        var err;
        var subdomain = "logger-test";

        env.LOGGLY_SUBDOMAIN = subdomain;
        logger.init();
        loggerLoggly.init();

        if (settings.logger.loggly.subdomain != subdomain) {
            err = "Loggly subdomain not updated. Expected '" + subdomain + "', got '" + settings.logger.loggly.subdomain + "'.";
        }

        env.LOGGLY_SUBDOMAIN = null;
        done(err);
    });

    it("Updates mailer settings", function (done) {
        var err;
        var login = "mailer-test";

        env.MAILGUN_SMTP_LOGIN = login;
        mailer.init();

        if (settings.mailer.smtp.user != login) {
            err = "Mailer login name not updated. Expected '" + login + "', got '" + settings.mailer.smtp.user + "'.";
        }

        env.MAILGUN_SMTP_LOGIN = null;
        done(err);
    });
});