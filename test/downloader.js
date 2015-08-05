// TEST: DOWNLOADER

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Downloader Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("settings.test.keys.json");
    settings.loadFromJson("../plugins/downloader/settings.default.json");

    var fs = require("fs");
    var utils = null;
    var downloader = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        utils = require("../lib/utils.coffee");
        downloader = require("../plugins/downloader/index.coffee");
        downloader.expresser = require("../index.coffee");
        downloader.expresser.events = require("../lib/events.coffee");
        downloader.expresser.logger = require("../lib/logger.coffee");
    });

    it("Has settings defined", function() {
        settings.should.have.property("downloader");
    });

    it("Inits", function() {
        downloader.init();
    });

    it("Download with redirect (Google index html)", function(done) {
        this.timeout(10000);

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

    it("Force stop a download", function(done) {
        this.timeout(10000);
        settings.downloader.preventDuplicates = false;

        var d, saveTo, downUrl;

        var callback = function(err, obj) {
            done();
        };

        saveTo = __dirname + "/download-test-stop.zip";
        downUrl = "http://ipv4.download.thinkbroadband.com/100MB.zip";
        d = downloader.download(downUrl, saveTo, callback);
        d.stop()
    });

    it("Prevent duplicate downloads", function(done) {
        this.timeout(10000);
        settings.downloader.preventDuplicates = true;

        var d1, d2, saveTo, downUrl;

        var callback1 = function(err, obj) {
            try {
                if (fs.existsSync(obj.saveTo)) {
                    fs.unlinkSync(obj.saveTo);
                }
            } catch (ex) {
                done(ex);
            }
        };

        var callback2 = function(err, obj) {
            d1.stop();

            if (err && err.duplicate && d1 != d2) {
                done();
            } else {
                done("Duplicate download was not prevented, or returned download objects are equal.");
            }
        };

        saveTo = __dirname + "/download-test.zip";
        downUrl = "http://ipv4.download.thinkbroadband.com/5MB.zip";
        d1 = downloader.download(downUrl, saveTo, callback1);
        d2 = downloader.download(downUrl, saveTo, callback2);
    });
});
