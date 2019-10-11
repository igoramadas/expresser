"use strict";
// Expresser: index.ts
/** Main Expresser class. */
class Expresser {
    /** Default App constructor. */
    constructor() {
        /** [[App]] exposed as .app */
        this.app = require("./app");
        /** [[Routes]] exposed as .routes */
        this.routes = require("./routes");
        this.version = JSON.parse(require("fs").readFileSync(`${__dirname}/../package.json`, { encoding: "utf8" })).version;
    }
    /** @hidden */
    static get Instance() {
        return this._instance || (this._instance = new this());
    }
    /** Returns a new fresh instance of the App module. */
    newInstance() {
        return new Expresser();
    }
}
module.exports = Expresser.Instance;
