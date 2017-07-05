// TEST: AWS - S3

require("coffeescript/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("AWS S3 Tests", function() {
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

    before(function() {
        settings.loadFromJson("../plugins/aws/settings.default.json");
        settings.loadFromJson("settings.test.json");

        utils = require("../lib/utils.coffee");

        aws = require("../plugins/aws/index.coffee");
        aws.expresser = require("../index.coffee");
        aws.expresser.events = require("../lib/events.coffee");
        aws.expresser.logger = require("../lib/logger.coffee");

        aws.init();
    });

    if (hasKeys) {
        it("Upload test file to S3", async function(done) {
            uploadTimestamp = moment().unix();

            var contents = {
                timestamp: uploadTimestamp
            };

            try {
                var result = await aws.s3.upload("expresser.devv.com", "test-s3.json", JSON.stringify(contents, null, 2));
                done();
            } catch (ex) {
                done("Could not upload file to S3: " + ex);
            }
        });

        it("Download uploaded file from S3", function(done) {
            var callback = function(err, result) {
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

        it("Delete file from S3", function() {
            var callback = function(err, result) {
                if (err) {
                    done("Could not delete file from S3: " + err);
                } else {
                    done();
                }
            };

            aws.s3.delete("expresser.devv.com", "test-s3.json", callback);
        });
    }
});
