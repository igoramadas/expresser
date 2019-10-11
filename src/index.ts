// Expresser: index.ts

/** Main Expresser class. */
class Expresser {
    private static _instance: Expresser
    /** @hidden */
    static get Instance() {
        return this._instance || (this._instance = new this())
    }

    /** Returns a new fresh instance of the App module. */
    newInstance(): Expresser {
        return new Expresser()
    }

    /** Default App constructor. */
    constructor() {
        this.version = JSON.parse(require("fs").readFileSync(`${__dirname}/../package.json`, {encoding: "utf8"})).version
    }

    /** [[App]] exposed as .app */
    app = require("./app")
    /** [[Routes]] exposed as .routes */
    routes = require("./routes")
    /** Library version */
    version: string
}

// Exports...
export = Expresser.Instance
