/** Main Expresser class. */
declare class Expresser {
    private static _instance;
    /** @hidden */
    static readonly Instance: Expresser;
    /** Returns a new fresh instance of the App module. */
    newInstance(): Expresser;
    /** Default App constructor. */
    constructor();
    /** [[App]] exposed as .app */
    app: any;
    /** Library version */
    version: string;
}
declare const _default: Expresser;
export = _default;
