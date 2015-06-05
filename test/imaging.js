// TEST: IMAGING

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Imaging Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    if (!settings.testKeysLoaded) {
        settings.loadFromJson("settings.test.keys.json");
        settings.testKeysLoaded = true;
    }

    var utils = null;
    var imaging = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        utils = require("../lib/utils.coffee");

        imaging = require("../plugins/imaging/index.coffee");
    });
});
