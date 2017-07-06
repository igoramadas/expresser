// TEST: GOOGLE CLOUD - STORAGE

require("coffeescript/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("^Google Cloud Storage Tests", function() {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var fs = require("fs");
    var moment = require("moment");
    var gcloud = null;

    before(function() {
        settings.loadFromJson("../plugins/gcloud/settings.default.json");
        settings.loadFromJson("settings.test.json");

        utils = require("../lib/utils.coffee");

        gcloud = require("../plugins/gcloud/index.coffee");
        gcloud.expresser = require("../index.coffee");
        gcloud.expresser.events = require("../lib/events.coffee");
        gcloud.expresser.logger = require("../lib/logger.coffee");

        gcloud.init();
    });

    it.skip("Upload file to storage", function() {});
});
