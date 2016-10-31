// TEST: SETTINGS

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Settings Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("settings.test.json");

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
        if (process.versions.node.indexOf(".10.") > 0) {
            var originalJson = fs.readFileSync(filename, {encoding: "utf8"});
        } else {
            var originalJson = fs.readFileSync(filename, "utf8");
        }
        var newJson = utils.minifyJson(originalJson);

        var callback = function() {
            if (process.versions.node.indexOf(".10.") > 0) {
                fs.writeFileSync(filename, originalJson, {encoding: "utf8"});
            } else {
                fs.writeFileSync(filename, originalJson, "utf8");
            }
            unwatch();
            done();
        };

        var unwatch = function() {
            settings.watch(false, callback);
        };

        settings.watch(true, callback);
        newJson.testingFileWatcher = true;

        try {
            fs.writeFileSync(filename, JSON.stringify(newJson, null, 4));
        } catch (ex) {
            done(ex);
        }
    });

    it("Encrypt and decrypt settings data", function(done) {
        this.timeout(10000);

        var filename = "./settings.test.crypt.json";
        if (process.versions.node.indexOf(".10.") > 0) {
            var originalJson = fs.readFileSync(filename, {encoding: "utf8"});
        } else {
            var originalJson = fs.readFileSync(filename, "utf8");
        }

        var callback = function(err) {
            if (err) done(err);
            else done();
        };

        if (!settings.encrypt(filename)) {
            return callback("Could not encrypt properties of settings.test.json file.")
        }

        var encrypted = JSON.parse(fs.readFileSync(filename, {encoding: "utf8"}));

        if (!encrypted.encrypted) {
            return callback("Property 'encrypted' was not properly set.")
        } else if (encrypted.app.title == "Expresser Settings Encryption") {
            return callback("Encryption failed, settings.app.title is still set as 'Expresser'.")
        }

        settings.decrypt(filename);

        var decrypted = JSON.parse(fs.readFileSync(filename, {encoding: "utf8"}));

        if (decrypted.encrypted) {
            return callback("Property 'encrypted' was not unset / deleted.")
        } if (decrypted.app.title != "Expresser Settings Encryption") {
            return callback("Decryption failed, settings.app.title is still encrypted.")
        }

        callback();
    });
});
