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
        it("Upload test file to S3", async function() {
            uploadTimestamp = moment().unix();

            var contents = {
                timestamp: uploadTimestamp
            };

            return await aws.s3.upload("expresser.devv.com", "test-s3.json", JSON.stringify(contents, null, 2));
        });

        it("Download uploaded file from S3", async function() {
            var result = await aws.s3.download("expresser.devv.com", "test-s3.json");
            var contents = JSON.parse(result);

            return new Promise((resolve, reject) => {
                if (contents.timestamp != uploadTimestamp) {
                    reject("Timestamp of uploaded file does not match: " + contents.timestamp + ", " + uploadTimestamp);
                } else {
                    resolve();
                }
            });
        });

        it("Delete file from S3", async function() {
            return await aws.s3.delete("expresser.devv.com", "test-s3.json");
        });
    }
});
