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

    it("Creates directory recursively", function (done) {
        this.timeout = 5000;

        var target = __dirname + "/some/directory/inside/another";
        var checkDir = function () {
            var stat = fs.statSync(target);

            if (stat.isDirectory()) {
                done();
            } else {
                done("Folder " + target + " was not created.");
            }
        };

        utils.mkdirRecursive(target);

        setTimeout(1000, checkDir);
    });

    it("Get valid server info", function (done) {
        var serverInfo = utils.getServerInfo();

        if (serverInfo.cpuCores > 0) {
            done();
        } else {
            done("Could not get CPU core count from server info result.");
        }
    });
});