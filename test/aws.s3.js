// TEST: AWS - S3

require("coffeescript/register")
var env = process.env
var chai = require("chai")
chai.should()

describe("AWS S3 Tests", function() {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test"

    var settings = require("../lib/settings.coffee")
    var fs = require("fs")
    var moment = require("moment")
    var aws = null
    var hasKeys = false
    var uploadTimestamp = 0

    if (env["AWS_ACCESS_KEY_ID"] || env["AWS_SECRET_ACCESS_KEY"] || env["AWS_CONFIGURED"]) {
        hasKeys = true
    }

    before(function() {
        settings.loadFromJson("../plugins/aws/settings.default.json")
        settings.loadFromJson("settings.test.json")

        utils = require("../lib/utils.coffee")

        aws = require("../plugins/aws/index.coffee")
        aws.expresser = require("../lib/index.coffee")
        aws.expresser.events = require("../lib/events.coffee")
        aws.expresser.logger = require("../lib/logger.coffee")

        aws.init()
    })

    if (hasKeys) {
        it("Upload test file to S3", async function() {
            this.timeout(5000)

            uploadTimestamp = moment().unix()

            var contents = {
                timestamp: uploadTimestamp
            }

            var options = {
                bucket: "expresser.devv.com",
                key: "test-" + uploadTimestamp + ".json",
                body: JSON.stringify(contents, null, 2)
            }

            return await aws.s3.upload(options)
        })

        it("Download uploaded file from S3", async function() {
            this.timeout(5000)

            var options = {
                bucket: "expresser.devv.com",
                key: "test-" + uploadTimestamp + ".json"
            }

            var result = await aws.s3.download(options)
            var contents = JSON.parse(result)

            return new Promise((resolve, reject) => {
                if (contents.timestamp != uploadTimestamp) {
                    reject("Timestamp of uploaded file does not match: " + contents.timestamp + ", " + uploadTimestamp)
                } else {
                    resolve()
                }
            })
        })

        it("Delete file from S3", async function() {
            this.timeout(5000)

            var options = {
                bucket: "expresser.devv.com",
                keys: "test-" + uploadTimestamp + ".json"
            }

            return await aws.s3.delete(options)
        })
    }
})
