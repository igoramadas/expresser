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

        utils.mkdirRecursive(recursiveTarget);

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

    it("Generate unique IDs", function (done) {
        var ids = [];
        var max = 500;
        var i;

        for (i = 0; i < max; i++) {
            ids.push(utils.uuid());
        }

        var noduplicates = lodash.uniq(ids);

        if (noduplicates.length == max) {
            done();
        } else {
            done("Out of " + max + ", " + max - noduplicates.length + " of the generated IDs were not unique.");
        }
    });
});