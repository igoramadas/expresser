// TEST: DOWNLOADER

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Downloader Tests", function() {
    process.env.NODE_ENV = "test";

    var fs = require("fs");
    var settings = require("../lib/settings.coffee");
    var utils = null;
    var downloader = null;

    before(function() {
        utils = require("../lib/utils.coffee");
        utils.loadDefaultSettingsFromJson();

        downloader = require("../lib/downloader.coffee");
    });

    it("Is single instance", function() {
        downloader.singleInstance = true;
        var downloader2 = require("../lib/downloader.coffee");
        downloader.singleInstance.should.equal(downloader2.singleInstance);
    });

    it("Has settings defined", function() {
        settings.should.have.property("downloader");
    });

    it("Download with redirect (Google index html)", function(done) {
        this.timeout(8000);

        var callback = function(err, obj) {
            if (err) {
                throw err;
            } else {
                fs.unlinkSync(obj.saveTo);
                done();
            }
        };

        var saveTo = __dirname + "/download-google.html";
        downloader.download("http://google.com/", saveTo, callback);
    });

    it("Prevent duplicate downloads", function(done) {
        settings.downloader.preventDuplicates = true;

        var callback1 = function(err, obj) {
            try {
                fs.unlinkSync(obj.saveTo);
            } catch (ex) {
                // Ignore unlink / deletion problems.
            }
        };

        var callback2 = function(err, obj) {
            if (err && err.duplicate) {
                done();
            }
        };

        var saveTo = __dirname + "/download-test.zip";
        var downUrl = "http://ipv4.download.thinkbroadband.com/5MB.zip";
        downloader.download(downUrl, saveTo, callback1);
        downloader.download(downUrl, saveTo, callback2);
    });
});