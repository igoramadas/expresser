// Expresser: index.ts

/** @hidden */
let version

// Get package version.
try {
    version = JSON.parse(require("fs").readFileSync(`${__dirname}/../package.json`, {encoding: "utf8"})).version
} catch (ex) {
    version = null
}

/** Exposes relevant modules. */
let index = {
    /** [[App]] exposed as .app */
    app: require("./data"),
    /** Library version */
    version: version
}

export = index
