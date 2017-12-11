// TEST: GOOGLE CLOUD - DATASTORE

require("coffeescript/register")
var env = process.env
var chai = require("chai")
chai.should()

describe("^Google Cloud Datastore Tests", function() {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test"

    var settings = require("../lib/settings.coffee")
    var fs = require("fs")
    var moment = require("moment")
    var gcloud = null
    var hasKeys = false
    var uploadTimestamp = 0

    before(function() {
        settings.loadFromJson("../plugins/gcloud/settings.default.json")
        settings.loadFromJson("settings.test.json")

        utils = require("../lib/utils.coffee")

        gcloud = require("../plugins/gcloud/index.coffee")
        gcloud.expresser = require("../lib/index.coffee")
        gcloud.expresser.events = require("../lib/events.coffee")
        gcloud.expresser.logger = require("../lib/logger.coffee")

        gcloud.init()
    })

    it.skip("Create an entity on the datastore", async function(done) {
        uploadTimestamp = moment().unix()

        var data = {
            timestamp: uploadTimestamp,
            title: "This is a test entity"
        }

        try {
            gcloud.datastore.upsert("test", data)
        } catch (ex) {
            done(ex)
        }
    })

    it.skip("Get all test entities from the datastore", async function(done) {
        try {
            gcloud.datastore.get("test")
        } catch (ex) {
            done(ex)
        }
    })
})
