// TEST: SETTINGS

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Settings Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var fs = require("fs");
    var utils = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        utils = require("../lib/utils.coffee");
    });

    it("Is single instance", function() {
        settings.singleInstance = true;
        var settings2 = require("../lib/settings.coffee");
        settings.singleInstance.should.equal(settings2.singleInstance);
    });

    it("All module have settings defined", function() {
        settings.should.have.property("general");
        settings.should.have.property("app");
        settings.should.have.property("database");
        settings.should.have.property("firewall");
        settings.should.have.property("logger");
        settings.should.have.property("mail");
        settings.should.have.property("sockets");
        settings.should.have.property("twitter");
    });

    it("Settings file watchers properly working", function(done) {
        this.timeout(10000);

        var originalJson = fs.readFileSync("./settings.test.json", {encoding: "utf8"});
        var newJson = utils.minifyJson(originalJson);

        var callback = function(event, filename) {
            fs.writeFileSync("./settings.test.json", originalJson);
            done();
        };

        utils.watchSettingsFiles(true, callback);
        newJson.testingFileWatcher = true;

        try {
            fs.writeFileSync("./settings.test.json", JSON.stringify(newJson, null, 4));
        } catch (ex) {
            done(ex);
        }
    });
});