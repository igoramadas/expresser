/*
 * Based on the node-loggly package.
 */

var loggly = exports
loggly.version = require("../package.json").version
loggly.createClient = require("./client.js").createClient
loggly.serialize = require("./common.js").serialize
loggly.Loggly = require("./client.js").Loggly
