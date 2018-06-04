// Temporarily disable till coffee-coverage gets compatible with CoffeeScript 2.2+
return

var coffeeCoverage = require("coffee-coverage")
var coverageVar = coffeeCoverage.findIstanbulVariable()
var writeOnExit = coverageVar == null ? true : null

coffeeCoverage.register({
    instrumentor: "istanbul",
    basePath: process.cwd(),
    exclude: ["/test", "/build", "/node_modules", "/plugins/mailer/node_modules", "/docs", "/.git", "/.history", "./src/app/"],
    coverageVar: coverageVar,
    writeOnExit: writeOnExit ? ((_ref = process.env.COFFEECOV_OUT) != null ? _ref : "coverage/coverage-coffee.json") : null,
    initAll: (_ref = process.env.COFFEECOV_INIT_ALL) != null ? _ref === "true" : true
})
