// TEST: LEGACY

let chai = require("chai")
let getPort = require("get-port")
let mocha = require("mocha")
let after = mocha.after
let before = mocha.before
let describe = mocha.describe
let it = mocha.it

chai.should()

describe("App Logger Tests", function() {
    let _ = require("lodash")
    let app
    let legacy
    let logger
    let setmeup

    before(async function() {
        setmeup = require("setmeup")
        setmeup.load()
        settings = setmeup.settings
        settings.logger.removeFields = ["username"]

        logger = require("anyhow")
        logger.setup("none")

        app = require("../lib/app").newInstance()
        legacy = require("../plugins/legacy/index.js")
    })

    after(function() {
        if (app && app.kill) {
            app.kill()
        }
    })

    it("Init the legacy module", function(done) {
        legacy.init(app)
        done()
    })
})
