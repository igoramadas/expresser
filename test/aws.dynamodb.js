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

        it("Create 5 new items on DynamoDB", async function() {
            this.timeout(30000)
            await utils.io.sleep(10000)

            var i, params

            for (i = 1; i < 6; i++) {
                params = {
                    TableName: tableName,
                    Item: {
                        title: "item-" + i,
                        random: Math.round(Math.random() * 100),
                        details: "This is a test item " + i
                    }
                }

                result = await aws.dynamodb.put(params)
            }

            return result
        })

        it("Query items from DynamoDB", async function() {
            var params = {
                TableName: tableName,
                KeyConditionExpression: "#t = :title",
                ExpressionAttributeNames: {
                    "#t": "title"
                },
                ExpressionAttributeValues: {
                    ":title": "item-1"
                }
            }

            return await aws.dynamodb.query(params)
        })

        it("Deletes the created test table on DynamoDB", async function() {
            var params = {
                TableName: tableName
            }

            return await aws.dynamodb.deleteTable(params)
        })
    }
})
