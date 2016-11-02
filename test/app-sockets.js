// TEST: APP SOCKETS

require("coffee-script/register");
var chai = require("chai");
chai.should();

describe("App Sockets Tests", function () {
    var env = process.env;
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var app = null;
    var sockets = null;
    var socketClient = require("socket.io-client");
    var supertest = require("supertest");

    var socketClientOptions = {
        transports: ["websocket"],
        forceNew: true
    };

    before(function () {
        settings.loadFromJson("../plugins/sockets/settings.default.json");
        settings.loadFromJson("settings.test.json");
        settings.app.port = 18003;

        app = require("../lib/app.coffee").newInstance();

        sockets = require("../plugins/sockets/index.coffee");
        sockets.expresser = require("../index.coffee");
        sockets.expresser.events = require("../lib/events.coffee");
        sockets.expresser.logger = require("../lib/logger.coffee");
    });

    it("Has sockets settings defined", function () {
        settings.should.have.property("sockets");
    });

    it("Init app server with sockets, port 18003", function () {
        this.timeout(5000);

        sockets.init();
        app.init();
    });

    it("Emits sockets message from client to server", function (done) {
        this.timeout(5000);

        var client;

        var clientToServer = function (value) {
            if (client) {
                client.disconnect();
            }

            if (value == "test123") {
                return done();
            }

            done("Expected socket message value is true, but got " + value + ".");
        };

        var clientConnected = function (err, res) {
            if (err) {
                return done(err);
            }

            client.emit("client-to-server", "test123");
        };

        sockets.listenTo("client-to-server", clientToServer, false);
        client = socketClient("http://localhost:18003/", socketClientOptions);
        client.on("connect", clientConnected);
    });

    it("Emits sockets message from server to client", function (done) {
        this.timeout(5000);

        var client;

        var serverToClient = function (value) {
            if (client) {
                client.disconnect();
            }

            if (value == "test123") {
                return done();
            }

            done("Expected socket message value is true, but got " + value + ".");
        };

        var clientConnected = function (err, res) {
            if (err) {
                return done(err);
            }

            client.on("server-to-client", serverToClient);
            sockets.emit("server-to-client", "test123");
        };

        client = socketClient("http://localhost:18003/", socketClientOptions);
        client.on("connect", clientConnected);
    });
});