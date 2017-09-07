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
    var emptyTitle = "empty"
    var emptyYear = 1999
    var itemsCount = 5

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
            this.timeout(30000)

            var params = {
                TableName: tableName,
                ProvisionedThroughput: { ReadCapacityUnits: 1, WriteCapacityUnits: 1 },
                KeySchema: [
                    {
                        AttributeName: "year",
                        KeyType: "HASH"
                    },
                    {
                        AttributeName: "title",
                        KeyType: "RANGE"
                    }
                ],
                AttributeDefinitions: [
                    {
                        AttributeName: "year",
                        AttributeType: "N"
                    },
                    {
                        AttributeName: "title",
                        AttributeType: "S"
                    }
                ]
            }

            var result = await aws.dynamodb.createTable(params)
            await utils.io.sleep(10000)

            return result
        })

        it("Create a new single item with empty details", async function() {
            var params = {
                TableName: tableName,
                Item: {
                    year: emptyYear,
                    title: emptyTitle
                }
            }

            return await aws.dynamodb.put(params)
        })

        it("Create 5 new items on DynamoDB", async function() {
            var i, params

            for (i = 1; i <= itemsCount; i++) {
                params = {
                    TableName: tableName,
                    Item: {
                        year: Math.round(Math.random() * 18) + 2000,
                        title: "item-" + i,
                        details: "This is item " + i + " out of " + itemsCount
                    }
                }

                result = await aws.dynamodb.put(params)
            }

            return result
        })

        it("Scan non empty items from DynamoDB, must return 5 items", async function() {
            var params = {
                TableName: tableName,
                FilterExpression: "#yr > :num",
                ExpressionAttributeNames: {
                    "#yr": "year"
                },
                ExpressionAttributeValues: {
                    ":num": emptyYear
                }
            }

            var result = await aws.dynamodb.scan(params)
            var count = result.Items ? result.Items.length : 0

            if (count == itemsCount) {
                return result
            } else {
                throw "Should return " + itemsCount + " items, but got " + count
            }
        })

        it("Query empty items from DynamoDB, must return 1 item", async function() {
            var params = {
                TableName: tableName,
                KeyConditionExpression: "#y = :num",
                ExpressionAttributeNames: {
                    "#y": "year"
                },
                ExpressionAttributeValues: {
                    ":num": emptyYear
                }
            }

            var result = await aws.dynamodb.query(params)
            var count = result.Items ? result.Items.length : 0

            if (count == 1) {
                return result
            } else {
                throw "Should return " + itemsCount + " items, but got " + count
            }
        })

        it("Get the empty item created on previous test", async function() {
            var params = {
                TableName: tableName,
                Key: {
                    year: emptyYear,
                    title: emptyTitle
                }
            }

            var result = await aws.dynamodb.get(params)

            if (result.Item) {
                return result
            } else {
                throw "Did not return the '" + emptyTitle + "' item created on the previous test."
            }
        })

        it("Deletes the empty item created on previous test", async function() {
            var params = {
                TableName: tableName,
                Key: {
                    year: emptyYear,
                    title: emptyTitle
                }
            }

            return await aws.dynamodb.delete(params)
        })

        it("Deletes the created test table on DynamoDB", async function() {
            var params = {
                TableName: tableName
            }

            return await aws.dynamodb.deleteTable(params)
        })
    }
})
