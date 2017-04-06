// TEST: AWS

require("coffee-script/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("AWS Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var aws = null;

    before(function () {
        settings.loadFromJson("../plugins/aws/settings.default.json");
        settings.loadFromJson("settings.test.json");

        utils = require("../lib/utils.coffee");

        aws = require("../plugins/aws/index.coffee");
        aws.expresser = require("../index.coffee");
        aws.expresser.events = require("../lib/events.coffee");
        aws.expresser.logger = require("../lib/logger.coffee");
    });

    it("Has settings defined", function () {
        settings.should.have.property("aws");
    });

    it("Inits", function () {
        aws.init();
    });

    it.skip("Upload test file to S3", function () {
        var callback = function (err, result) {

        };

        aws.s3.upload("expresser.devv.com", "testimage.jpg", image, callback);
    });

    it.skip("Download uploaded file from S3", function () {

    });

    it.skip("Delete file from S3", function () {

    });
});
