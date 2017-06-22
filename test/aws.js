// TEST: AWS

require("coffee-script/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("AWS Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var fs = require("fs");
    var moment = require("moment");
    var aws = null;
    var hasKeys = false;
    var uploadTimestamp = 0;

    if (env["AWS_ACCESS_KEY_ID"] || env["AWS_SECRET_ACCESS_KEY"] || env["AWS_CONFIGURED"]) {
        hasKeys = true;
    }

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

    if (hasKeys) {
        it("Upload test file to S3", function (done) {
            uploadTimestamp = moment().unix();

            var contents = {
                timestamp: uploadTimestamp
            };

            var callback = function (err, result) {
                if (err) {
                    done("Could not upload file to S3: " + err);
                } else {
                    done();
                }
            };

            aws.s3.upload("expresser.devv.com", "test-s3.json", JSON.stringify(contents, null, 2), callback);
        });

        it("Download uploaded file from S3", function (done) {
            var callback = function (err, result) {
                if (err) {
                    done("Could not upload file to S3: " + err);
                } else {
                    var contents = JSON.parse(result);

                    if (contents.timestamp != uploadTimestamp) {
                        done("Timestamp of uploaded file does not match: " + contents.timestamp + ", " + uploadTimestamp);
                    } else {
                        done();
                    }
                }
            };

            aws.s3.download("expresser.devv.com", "test-s3.json", callback);
        });

        it("Delete file from S3", function () {

        });
    }
});
