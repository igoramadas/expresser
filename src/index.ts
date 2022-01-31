// Expresser: index.ts

import {App} from "./app"
import {Routes} from "./routes"

/** Main Expresser class. */
class Expresser {
    private static _instance: Expresser
    /** @hidden */
    static get Instance() {
        return this._instance || (this._instance = new this())
    }

    /** Returns a new fresh instance of the App module. */
    /* istanbul ignore next */
    newInstance(): Expresser {
        return new Expresser()
    }

    /** [[App]] exposed as .app */
    app: App = App.Instance
    /** [[Routes]] exposed as .routes */
    routes: Routes = Routes.Instance
    /** Library version */
    version: string = JSON.parse(require("fs").readFileSync(`${__dirname}/../package.json`, {encoding: "utf8"})).version
}

// Exports...
export = Expresser.Instance
