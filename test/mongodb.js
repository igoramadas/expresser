// TEST: DATABASE MONGODB

require("coffeescript/register")
var env = process.env
var chai = require("chai")
chai.should()

describe("MongoDB Tests", function() {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test"

    var testTimestamp = require("moment")().valueOf()
    var settings = require("../lib/settings.coffee")
    var mongodb = null
    var dbMongo = null
    var recordId = null

    before(function() {
        settings.loadFromJson("../plugins/mongodb/settings.default.json")
        settings.loadFromJson("settings.test.json")

        if (env["MONGODB"]) {
            settings.mongodb.connString = env["MONGODB"]
        }

        mongodb = require("../plugins/mongodb/index.coffee")
        mongodb.expresser = require("../lib/index.coffee")
        mongodb.expresser.events = require("../lib/events.coffee")
        mongodb.expresser.logger = require("../lib/logger.coffee")
    })

    after(function() {
        var fs = require("fs")

        try {
            if (dbMongo.connection) {
                dbMongo.connection.close()
            }
        } catch (ex) {
            console.error("Could not close MongoDB connection.", ex)
        }
    })

    it("Has settings defined", function() {
        settings.should.have.property("mongodb")
    })

    if (settings.mongodb && settings.mongodb.connString) {
        it("Inits", function() {
            mongodb.init()
        })

        it("Connets", async function() {
            dbMongo = await mongodb.connect(settings.mongodb.connString, settings.mongodb.options)
            return dbMongo
        })
    }

    if (dbMongo) {
        it("Add 100 records to the database", function(done) {
            this.timeout(12000)

            var counter = 100
            var current = 1

            var callback = function(err, result) {
                if (err) {
                    done(err)
                } else if (current == counter) {
                    done()
                }

                current++
            }

            var execution = function() {
                for (var i = 0; i < counter; i++) {
                    dbMongo.insert(
                        "test", {
                            counter: i
                        },
                        callback
                    )
                }
            }

            setTimeout(execution, 100)
        })

        it("Add complex record to the database", function(done) {
            this.timeout(10000)

            var callback = function(err, result) {
                recordId = result._id

                if (err) {
                    done(err)
                } else {
                    done()
                }
            }

            var execution = function() {
                var obj = {
                    testId: testTimestamp,
                    complex: true,
                    date: new Date(),
                    data: [
                        1,
                        2,
                        "a",
                        "b",
                        {
                            sub: 0.5
                        }
                    ]
                }
                dbMongo.insert("test", obj, callback)
            }

            setTimeout(execution, 2000)
        })

        it("Get record added on the previous step, by filter", function(done) {
            var callback = function(err, result) {
                if (err) {
                    done(err)
                } else if (result.length > 0 && result[0].testId == testTimestamp) {
                    done()
                } else {
                    done("Expected one result with testId = " + testTimestamp + ", but got something else.")
                }
            }

            var filter = {
                testId: testTimestamp
            }

            dbMongo.get("test", filter, callback)
        })

        it("Get record added on the previous step, by ID", function(done) {
            var callback = function(err, result) {
                if (err) {
                    done(err)
                } else if (!result) {
                    done("No record returned for ID " + recordId)
                } else {
                    done()
                }
            }

            var filter = {
                _id: recordId
            }

            dbMongo.get("test", filter, callback)
        })

        it("Get all records from database", function(done) {
            var callback = function(err, result) {
                if (err) {
                    done(err)
                } else {
                    done()
                }
            }

            dbMongo.get("test", callback)
        })

        it("Get records from database, limit to 5", function(done) {
            var callback = function(err, result) {
                if (err) {
                    done(err)
                } else {
                    done()
                }
            }

            dbMongo.get(
                "test", {
                    limit: 5
                },
                callback
            )
        })

        it("Updates all previously created records on the database", function(done) {
            var callback = function(err, result) {
                if (err) {
                    done(err)
                } else {
                    done()
                }
            }

            var obj = {
                $set: {
                    updated: true
                }
            }

            dbMongo.update("test", obj, callback)
        })

        it("Count records on database collection", function(done) {
            var callback = function(err, count) {
                if (err) {
                    done(err)
                } else if (count < 1) {
                    done("Count should return at least 1 record (added on previous tests).")
                } else {
                    done()
                }
            }

            dbMongo.count("test", null, callback)
        })

        it("Remove record from database, by ID", function(done) {
            var callback = function(err, result) {
                if (err) {
                    done(err)
                } else {
                    done()
                }
            }

            var filter = {
                _id: recordId
            }

            dbMongo.remove("test", filter, callback)
        })

        it("Remove record from database, by filter", function(done) {
            var callback = function(err, result) {
                if (err) {
                    done(err)
                } else {
                    done()
                }
            }

            var filter = {
                complex: true
            }

            dbMongo.remove("test", filter, callback)
        })

        it("Tries to insert, update, remove, count using invalid params and connection", function(done) {
            var err = false
            var connection = dbMongo.connection
            var callback = function() {
                return false
            }

            dbMongo.connection = null

            try {
                dbMongo.get()
                err = "DatabaseMongoDb.get(missing params) should throw an error, but did not."
            } catch (ex) {}

            if (!err) {
                try {
                    dbMongo.get("test", {
                        something: true
                    })
                    err = "DatabaseMongoDb.get(invalid connection) should throw an error, but did not."
                } catch (ex) {}
            }

            if (!err) {
                try {
                    dbMongo.insert()
                    err = "DatabaseMongoDb.insert(missing params) should throw an error, but did not."
                } catch (ex) {}
            }

            if (!err) {
                try {
                    dbMongo.insert("invalid", {})
                    err = "DatabaseMongoDb.insert(invalid connection) should throw an error, but did not."
                } catch (ex) {}
            }

            if (!err) {
                try {
                    dbMongo.update()
                    err = "DatabaseMongoDb.update(missing params) should throw an error, but did not."
                } catch (ex) {}
            }

            if (!err) {
                try {
                    dbMongo.update("invalid", {})
                    err = "DatabaseMongoDb.update(invalid connection) should throw an error, but did not."
                } catch (ex) {}
            }

            if (!err) {
                try {
                    dbMongo.remove()
                    err = "DatabaseMongoDb.remove(missing params) should throw an error, but did not."
                } catch (ex) {}
            }

            if (!err) {
                try {
                    dbMongo.remove("invalid", {})
                    err = "DatabaseMongoDb.remove(invalid connection) should throw an error, but did not."
                } catch (ex) {}
            }

            if (!err) {
                try {
                    dbMongo.count()
                    err = "DatabaseMongoDb.count(missing params) should throw an error, but did not."
                } catch (ex) {}
            }

            if (!err) {
                try {
                    dbMongo.count("invalid", {})
                    err = "DatabaseMongoDb.count(invalid connection) should throw an error, but did not."
                } catch (ex) {}
            }

            dbMongo.connection = connection

            if (err) {
                done()
            } else {
                done(err)
            }
        })
    } else {
        it.skip("Database MongoDB tests skipped, no connection available")
    }
})
