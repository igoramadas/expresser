// TEST: AWS - DYNAMODB

require("coffeescript/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("AWS DynamoDB Tests", function() {
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
        it("Creates a table on DynamoDB", async function() {
            var params = {
                TableName: "Test",
                KeySchema: [{
                    AttributeName: "id",
                    KeyType: "HASH"
                }],
                AttributeDefinitions: [{
                        AttributeName: "title",
                        AttributeType: "S"
                    },
                    {
                        AttributeName: "timestamp",
                        AttributeType: "S"
                    }
                ],
                ProvisionedThroughput: {
                    ReadCapacityUnits: 1,
                    WriteCapacityUnits: 1
                }
            };

            var table = await aws.dynamodb.createTable(params);
        });
    }
});
