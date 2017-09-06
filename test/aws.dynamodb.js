// TEST: AWS - DynamoDB

require("coffeescript/register")
var env = process.env
var chai = require("chai")
chai.should()

describe("AWS DynamoDB Tests", function() {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test"

    var settings = require("../lib/settings.coffee")
    var fs = require("fs")
    var moment = require("moment")
    var aws = null
    var hasKeys = false
    var tableName = "Test-" + moment().unix()

    if (env["AWS_ACCESS_KEY_ID"] || env["AWS_SECRET_ACCESS_KEY"] || env["AWS_CONFIGURED"]) {
        hasKeys = true
    }

    before(function() {
        settings.loadFromJson("../plugins/aws/settings.default.json")
        settings.loadFromJson("settings.test.json")

        utils = require("../lib/utils.coffee")

        aws = require("../plugins/aws/index.coffee")
        aws.expresser = require("../index.coffee")
        aws.expresser.events = require("../lib/events.coffee")
        aws.expresser.logger = require("../lib/logger.coffee")

        aws.init()
    })

    if (hasKeys) {
        it("Create a table on DynamoDB", async function() {
            var params = {
                TableName: tableName,
                KeySchema: [{ AttributeName: "title", KeyType: "HASH" }],
                AttributeDefinitions: [{ AttributeName: "title", AttributeType: "S" }],
                ProvisionedThroughput: { ReadCapacityUnits: 1, WriteCapacityUnits: 1 }
            }

            return await aws.dynamodb.createTable(params)
        })

        it("Create a new item on DynamoDB", async function() {
            this.timeout(30000)

            await utils.io.sleep(12000)

            var params = {
                TableName: tableName,
                Item: {
                    title: "My test item",
                    year: moment().year(),
                    details: "This is a test item"
                }
            }

            return await aws.dynamodb.put(params)
        })

        it("Deletes the created test table on DynamoDB", async function() {
            var params = {
                TableName: tableName
            }

            return await aws.dynamodb.deleteTable(params)
        })
    }
})
