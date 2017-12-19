require("coffeescript/register")

var fs = require("fs")

if (fs.existsSync(__dirname + "/lib")) {
    module.exports = require("./lib/index.coffee")
} else {
    module.exports = require("./build/index.coffee")
}
