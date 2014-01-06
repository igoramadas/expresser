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

    it("Settings file watchers properly working", function(done) {
        this.timeout(10000);

        var filename = "./settings.test.json";
        var originalJson = fs.readFileSync(filename, {encoding: "utf8"});
        var newJson = utils.minifyJson(originalJson);

        var callback = function() {
            fs.writeFileSync(filename, originalJson);
            unwatch();
            done();
        };

        var unwatch = function() {
            utils.watchSettingsFiles(false, callback);
        };

        utils.watchSettingsFiles(true, callback);
        newJson.testingFileWatcher = true;

        try {
            fs.writeFileSync(filename, JSON.stringify(newJson, null, 4));
        } catch (ex) {
            done(ex);
        }
    });

    it("Encrypt and decrypt settings data", function(done) {
        this.timeout(10000);

        var filename = "./settings.test.json";
        if (process.versions.node.indexOf(".10.") > 0) {
            var originalJson = fs.readFileSync(filename, {encoding: "utf8"});
        } else {
            var originalJson = fs.readFileSync(filename, "utf8");
        }

        var callback = function(err) {
            if (err) done(err);
            else done();
        };

        if (!utils.encryptSettingsJson(filename)) {
            return callback("Could not encrypt properties of settings.test.json file.")
        }

        if (process.versions.node.indexOf(".10.") > 0) {
            var encrypted = JSON.parse(fs.readFileSync(filename, {encoding: "utf8"}));
        } else {
            var encrypted = JSON.parse(fs.readFileSync(filename, "utf8"));
        }

        if (!encrypted.encrypted) {
            return callback("Property 'encrypted' was not properly set.")
        } else if (encrypted.general.appTitle == "Expresser") {
            return callback("Encryption failed, settings.general.appTitle is still set as 'Expresser'.")
        }

        utils.decryptSettingsJson(filename);

        if (process.versions.node.indexOf(".10.") > 0) {
            var decrypted = JSON.parse(fs.readFileSync(filename, {encoding: "utf8"}));
        } else {
            var decrypted = JSON.parse(fs.readFileSync(filename, "utf8"));
        }

        if (decrypted.encrypted) {
            return callback("Property 'encrypted' was not unset / deleted.")
        } if (decrypted.general.appTitle != "Expresser") {
            return callback("Decryption failed, settings.general.appTitle is still encrypted.")
        }

        callback();
    });
});