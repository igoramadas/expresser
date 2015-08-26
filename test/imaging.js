// TEST: IMAGING

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Imaging Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("../plugins/imaging/settings.default.json");
    settings.loadFromJson("settings.test.json");
    settings.loadFromJson("settings.test.keys.json");

    var path = require("path");
    var imaging = null;
    var utils = null;

    var logoPath = path.join(__dirname, "../logo.png");

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        utils = require("../lib/utils.coffee");
        imaging = require("../plugins/imaging/index.coffee");
        imaging.expresser = require("../index.coffee");
        imaging.expresser.events = require("../lib/events.coffee");
        imaging.expresser.logger = require("../lib/logger.coffee");
    });

    it("Inits", function() {
        imaging.init();
    });

    it("Converts PNG logo to GIF", function(done) {
        this.timeout(10000);

        var callback = function(err, result) {
            if (!err)
            {
                done();
            }
            else
            {
                done(err)
            }
        };

        imaging.toGif(logoPath, callback);
    });
});
