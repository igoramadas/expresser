// TEST: UTILS

require("coffeescript/register");
var env = process.env;
var chai = require("chai");
var fs = require("fs");
chai.should();

describe("Utils Data Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var utils = require("../lib/utils.coffee");
    var lodash = require("lodash");

    it("Remove specified characters from string", function (done) {
        var original = "ABC123";
        var removed = utils.data.removeFromString(original, ["A", "1"]);

        if (removed == "BC23") {
            done();
        } else {
            done("Expected BC23, got " + removed);
        }
    });

    it("Mask a phone number", function (done) {
        var original = "176 55555 9090";
        var masked = utils.data.maskString(original, "*", 4);

        if (masked == "*** ***** 9090") {
            done();
        } else {
            done("Expected '*** ***** 9090', got '" + masked + "'.");
        }
    });

    it("Minify a JSON object, returning as string", function (done) {
        var original = {
            first: true,
            second: false,
            third: 0
        };

        var minified = utils.data.minifyJson(original, true);

        if (minified == '{"first":true,"second":false,"third":0}') {
            done();
        } else {
            done("JSON object was not minified properly: " + minified);
        }
    });

    it("Fail minifying a 'dirty' JSON string with invalid comments", function (done) {
        var original = "" +
            " /* comment here // " +
            " { first: true } // ";

        try {
            var minified = utils.data.minifyJson(original, true);
            done("Minifying an invalid JSON should throw an exception.");
        } catch (ex) {
            done();
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
