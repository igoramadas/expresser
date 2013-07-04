// TEST: DOWNLOADER

require("coffee-script");
var chai = require("chai");
chai.should();

describe("Downloader Tests", function() {
    process.env.NODE_ENV = "test";

    var env = process.env;
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

    it("Download (then delete) Google index html file", function(done) {
        var callback = function(err, obj) {
            if (err) {
                throw err;
            } else {
                fs.unlinkSync(obj.saveTo);
                done();
            }
        };

        var saveTo = __dirname + "google.html";
        downloader.download("http://google.com/", saveTo, callback);
    });
});