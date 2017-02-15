// TEST: APP SOCKETS

require("coffee-script/register");
var env = process.env;
var chai = require("chai");
chai.should();

describe("App Sockets Tests", function () {
    if (!env.NODE_ENV || env.NODE_ENV == "") env.NODE_ENV = "test";

    var settings = require("../lib/settings.coffee");
    var app = null;
    var sockets = null;
    var socketClient = require("socket.io-client");
    var supertest = require("supertest");

    var socketClientOptions = {
        autoConnect: true,
        transports: ["websocket"],
        forceNew: true
    };

    var socketError = function (err, done) {
        done(err);
    }

    before(function () {
        settings.loadFromJson("../plugins/sockets/settings.default.json");
        settings.loadFromJson("settings.test.json");
        settings.app.port = 8080;
        settings.app.ssl.enabled = false;

        app = require("../lib/app.coffee").newInstance();

        sockets = require("../plugins/sockets/index.coffee");
        sockets.expresser = require("../index.coffee");
        sockets.expresser.events = require("../lib/events.coffee");
        sockets.expresser.logger = require("../lib/logger.coffee");
    });

    after(function () {
        app.kill();
    });

    it("Has sockets settings defined", function () {
        settings.should.have.property("sockets");
    });

    it("Init app server with sockets, port 8080", function () {
        this.timeout(5000);

        sockets.init();
        app.init();
    });

    it("Emits sockets message from client to server, using 2 clients", function (done) {
        this.timeout(12000);

        var client, shadowClient;

        var clientToServer = function (value) {
            sockets.stopListening("client-to-server");

            if (shadowClient && shadowClient.connected) {
                shadowClient.disconnect();
            }

            if (client && client.connected) {
                client.disconnect();
            }

            if (value == "test123") {
                return done();
            }

            done("Expected socket message value is test123, but got " + value + ".");
        };

        var clientConnected = function (err, res) {
            if (err) {
                return done(err);
            }

            client.emit("client-to-server", "test123");
        };

        shadowClient = socketClient("http://localhost:8080/", socketClientOptions);
        sockets.listenTo("client-to-server", clientToServer, false);
        client = socketClient("http://localhost:8080/", socketClientOptions);

        client.on("connect", clientConnected);
        client.on("connect_error", function (err) {
            socketError(err, done);
        });
    });

    it("Emits sockets message from server to client", function (done) {
        this.timeout(12000);

        var client;

        var serverToClient = function (value) {
            if (client && client.connected) {
                client.disconnect();
            }

            if (value == "test123") {
                return done();
            }

            done("Expected socket message value is test123, but got " + value + ".");
        };

        var clientConnected = function (err, res) {
            if (err) {
                return done(err);
            }

            var emitter = function () {
                sockets.emit("welcome", "test123");
            }

            setTimeout(emitter, 500);
        };

        client = socketClient("http://localhost:8080/", socketClientOptions);

        client.on("welcome", serverToClient);
        client.on("connect", clientConnected);
        client.on("connect_error", function (err) {
            socketError(err, done);
        });
    });

    it("Compacts list of current listeners", function () {
        sockets.compact();
    });

    it("Fails to emit and listen to events with sockets not initiated", function (done) {
        var err = false;
        var listener = function () {
            return true;
        };

        sockets.io = null;

        try {
            sockets.emit("invalid-io", true);
            err = "Sockets.emit should throw an error, but did not."
        } catch (ex) {}

        if (!err) {
            try {
                sockets.listenTo("invalid-io", listener);
                err = "Sockets.listenTo should throw an error, but did not."
            } catch (ex) {}
        }

        if (err) {
            done();
        } else {
            done(err);
        }
    });
});
