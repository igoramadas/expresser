// TEST: DATABASE

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Database Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var utils = null;
    var database = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        utils = require("../lib/utils.coffee");
        database = require("../lib/database.coffee");
    });

    it("Is single instance", function() {
        database.singleInstance = true;
        var database2 = require("../lib/database.coffee");
        database.singleInstance.should.equal(database2.singleInstance);
    });

    it("Has settings defined", function() {
        settings.should.have.property("database");
    });

    it("Inits and validates connection to localhost", function(done) {
        this.timeout(10000);

        var callbackValidated = function(result) {
            database.onConnectionValidated = null;
            database.onConnectionError = null;
            done();
        };

        var callbackError = function(err) {
            database.onConnectionValidated = null;
            database.onConnectionError = null;
            done(err);
        };

        settings.database.connString = "mongodb://127.0.0.1/expresser";

        database.onConnectionValidated = callbackValidated;
        database.onConnectionError = callbackError;
        database.init();
    });

    it("Add simple record to the database", function(done) {
        var callback = function(err, result) {
            if (err) {
                throw err;
            } else {
                done();
            }
        };

        var obj = {simple: true};

        database.set("test", obj, callback);
    });

    it("Add complex record to the database", function(done) {
        var callback = function(err, result) {
            if (err) {
                throw err;
            } else {
                done();
            }
        };

        var obj = {complex: true, date: new Date(), data: [1, 2, "a", "b", {sub: 0.5}]};

        database.set("test", obj, callback);
    });

    it("Switches to the failover database", function(done) {
        this.timeout(10000);

        var callbackFailover = function(failover) {
            database.onFailoverSwitch = null;
            if (failover) done();
            else done("Database failover flag is false.");
        };

        settings.database.retryInterval = 500;
        settings.database.connString = "abc:invalid:mongo/expresser";
        settings.database.connString2 = "mongodb://127.0.0.1/expresserFailover";

        database.onFailoverSwitch = callbackFailover;
        database.init();
    });

    it("Triggers 'onConnectionError' on init with invalid connection", function(done) {
        this.timeout(10000);

        var callbackError = function(err) {
            database.onConnectionError = null;
            if (err) done();
            else done("No error was returned!");
        };

        settings.database.connString = "abc:invalid:mongo/expresser";

        database.onConnectionError = callbackError;
        database.init();
    });
});