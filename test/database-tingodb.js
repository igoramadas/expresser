// TEST: DATABASE TINGODB

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("Database TingoDB Tests", function() {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    settings.loadFromJson("../plugins/database-tingodb/settings.default.json");
    settings.loadFromJson("settings.test.json");

    var database = null;
    var databaseTingo = null;
    var dbTingo = null;

    // TESTS STARTS HERE!!!
    // ----------------------------------------------------------------------------------

    before(function() {
        database = require("../lib/database.coffee".newInstance());

        databaseTingo = require("../plugins/database-tingodb/index.coffee");
        databaseTingo.expresser = require("../index.coffee");
        databaseTingo.expresser.events = require("../lib/events.coffee");
        databaseTingo.expresser.logger = require("../lib/logger.coffee");
        databaseTingo.expresser.database = database;
    });

    after(function()
    {
        var fs = require("fs");

        try {
            if (fs.existsSync(__dirname + "/database/test.tingo")) {
                fs.unlinkSync(__dirname + "/database/test.tingo");
            }            
        } catch (ex) {
            console.error("Could not delete TingoDB test database files.", ex);
        }
    });

    it("Has settings defined", function() {
        settings.database.should.have.property("tingodb");
    });

    it("Inits", function() {
        database.init();
        dbTingo = databaseTingo.init();
    });

    it("TingoDB - Add complex record to the database", function(done) {
        var callback = function(err, result) {
            if (err) {
                done(err);
            } else {
                done();
            }
        };

        var obj = {complex: true, date: new Date(), data: [1, 2, "a", "b", {sub: 0.5}]};

        dbTingo.insert("test", obj, callback);
    });
});
