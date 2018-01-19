// TEST: CRON

require("coffeescript/register")
var env = process.env
var chai = require("chai")
chai.should()

describe("Cron Tests", function() {
    env.NODE_ENV = "test"
    process.setMaxListeners(20)

    var settings = require("../lib/settings.coffee")
    var events = require("../lib/events.coffee")
    var utils = null
    var cron = null

    before(function() {
        settings.loadFromJson("../plugins/cron/settings.default.json")
        settings.loadFromJson("settings.test.json")

        utils = require("../lib/utils.coffee")

        cron = require("../plugins/cron/index.coffee")
        cron.expresser = require("../lib/index.coffee")
        cron.expresser.events = require("../lib/events.coffee")
        cron.expresser.logger = require("../lib/logger.coffee")
    })

    after(function() {
        for (var job of cron.jobs) {
            job.stop()
        }
    })

    it("Has settings defined", function() {
        settings.should.have.property("cron")
    })

    it("Inits", function() {
        cron.init()
    })

    it("Load jobs from a testcron-1.json and testcron-2.json files", function(done) {
        cron.load("test/testcron-1.json", {
            basePath: "../../../lib/",
            autoStart: false
        })

        cron.load("test/testcron-2.json", {
            basePath: "../../../lib/",
            autoStart: true
        })

        if (cron.jobs.length == 2) {
            done()
        } else {
            done("Cron should have 2 jobs loaded from testcron-1.json and testcron-2.json, but has " + cron.jobs.length + " jobs.")
        }
    })

    it("Fails to load when filename or file JSON data is not valid", function(done) {
        try {
            cron.load(true)
            return done("Cron.load(true) should have failed!")
        } catch (ex) {}

        try {
            cron.load("invalidfilename.json")
            done("Cron.load(invalidfilename) should have failed!")
        } catch (ex) {}

        try {
            cron.load("test/testcron-invalid.json", {
                autoStart: false,
                basePath: "../../../lib/"
            })
            done("Cron.load(testcron-invalid should have failed!")
        } catch (ex) {
            done()
        }
    })

    it("Start and stop a single specific job (job number 2)", function(done) {
        this.timeout(10000)

        var verify = function(ok) {
            events.off("cron-2", verify)
            cron.stop("cron-2")

            if (ok == 2) {
                done()
            } else {
                done("Event should emit 2, but we got " + ok)
            }
        }

        events.on("cron-2", verify)

        if (cron.start("cron-2").notFound) {
            done("Job was not found.")
        }
    })

    it("Start specific job that does not exist", function(done) {
        if (cron.start("cron-not-exist").notFound) {
            done()
        } else {
            done("Starting a job that does not exist should return notFound = true.")
        }
    })

    it("Start all loaded cron jobs", function(done) {
        this.timeout(10000)

        var verify = function(ok) {
            events.off("cron-seconds", verify)

            if (ok == "seconds") {
                done()
            } else {
                done("Event should emit 'seconds', but we got " + ok)
            }
        }

        events.on("cron-seconds", verify)

        cron.start()
    })

    it("Remove cron-seconds job loaded from testcron-1.json", function(done) {
        var length = cron.jobs.length
        cron.remove("cron-seconds")

        if (cron.jobs.length < length) {
            done()
        } else {
            done("Job cron-seconds was not removed from cron jobs list.")
        }
    })

    it("Add and run a cron job, passing itself to the callback", function(done) {
        var schedule = 1000
        var callback = function(jobRef) {
            if (jobRef.schedule == schedule) {
                done()
            } else {
                done("The job was not passed to the callback.")
            }
        }

        var job = {
            id: "testjob",
            callback: callback,
            schedule: schedule,
            once: true,
            autoStart: true
        }

        cron.add(job)
    })

    it("Throw error when adding invalid jobs", function(done) {
        var err = false

        try {
            cron.add({
                missing_id: true
            })
            err = "Cron.add(missing id) should throw an error, but did not."
        } catch (ex) {}

        if (!err) {
            try {
                cron.add({
                    id: 123,
                    callback: "invalid"
                })
                err = "Cron.add(invalid callback) should throw an error, but did not."
            } catch (ex) {}
        }

        if (err) {
            done()
        } else {
            done(err)
        }
    })

    it("Stop jobs", function(done) {
        cron.stop()

        for (var j = 0; j < cron.jobs.length; j++) {
            if (cron.jobs[j].timer != null) {
                return done("Cron still has jobs enabled after calling stop().")
            }
        }

        done()
    })

    it("Prevents duplicate jobs when 'allowReplacing' setting is false", function(done) {
        settings.cron.allowReplacing = false

        var callback = function() {
            return true
        }

        var job1 = {
            id: "uniqueJob",
            callback: callback,
            schedule: 1000,
            once: true
        }

        var job2 = {
            id: "uniqueJob",
            callback: callback,
            schedule: 2000,
            once: false
        }

        try {
            cron.add(job1)
            cron.add(job2)
            done("Duplicate job was added, and it shouldn't be.")
        } catch (ex) {
            done()
        }
    })

    it("Do not start cron jobs when module is not enabled", function(done) {
        settings.cron.enabled = false

        if (!cron.load().notEnabled) {
            done("Cron.load should not run when settings.cron.enabled is false.")
        } else if (!cron.start().notEnabled) {
            done("Cron.start should not run when settings.cron.enabled is false.")
        } else {
            done()
        }
    })
})
