// TEST: UTILS

require("coffee-script/register");
var env = process.env;
var chai = require("chai");
var fs = require("fs");
chai.should();

describe("Utils Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var utils = require("../lib/utils.coffee");
    var lodash = require("lodash");

    var recursiveTarget = __dirname + "/mkdir/directory/inside/another";

    var cleanup = function () {
        if (fs.existsSync(recursiveTarget)) {
            fs.rmdirSync(__dirname + "/mkdir/directory/inside/another");
            fs.rmdirSync(__dirname + "/mkdir/directory/inside");
            fs.rmdirSync(__dirname + "/mkdir/directory");
            fs.rmdirSync(__dirname + "/mkdir");
        }
    };

    before(function () {
        cleanup();
    });

    after(function () {
        cleanup();
    });

    it("Creates directory recursively", function (done) {
        this.timeout = 5000;

        var checkDir = function () {
            var stat = fs.statSync(recursiveTarget);

            if (stat.isDirectory()) {
                done();
            } else {
                done("Folder " + recursiveTarget + " was not created.");
            }
        };

        utils.io.mkdirRecursive(recursiveTarget);

        setTimeout(checkDir, 1000);
    });

    it("Get valid server info", function (done) {
        var serverInfo = utils.getServerInfo();

        if (serverInfo.cpuCores > 0) {
            done();
        } else {
            done("Could not get CPU core count from server info result.");
        }
    });

    it("Check IP against multiple ranges", function (done) {
        var ip = "192.168.1.1";
        var validIP = "192.168.1.1";
        var validRange = "192.168.1.0/24";
        var validRangeArray = ["192.168.1.0/24", "192.168.0.0/16"];
        var invalidRange = "10.1.1.0/16";

        if (!utils.network.ipInRange(ip, validIP)) {
            done("IP " + ip + " should be valid against " + validIP + ".")
        } else if (!utils.network.ipInRange(ip, validRange)) {
            done("IP " + ip + " should be valid against " + validRange + ".")
        } else if (!utils.network.ipInRange(ip, validRangeArray)) {
            done("IP " + ip + " should be valid against " + validRangeArray.join(", ") + ".")
        } else if (!utils.network.ipInRange(ip, validIP)) {
            done("IP " + ip + " should be invalid against " + invalidRange + ".")
        } else {
            done();
        }
    });

    it("Check IP against multiple ranges", function (done) {
        var serverInfo = utils.system.getInfo();

        if (serverInfo.cpuCores > 0) {
            done();
        } else {
            done("Could not get CPU core count from server info result.");
        }
    });

    it("Generate unique IDs", function (done) {
        var ids = [];
        var max = 500;
        var i;

        for (i = 0; i < max; i++) {
            ids.push(utils.data.uuid());
        }

        var noduplicates = lodash.uniq(ids);

        if (noduplicates.length == max) {
            done();
        } else {
            done("Out of " + max + ", " + max - noduplicates.length + " of the generated IDs were not unique.");
        }
    });
});
