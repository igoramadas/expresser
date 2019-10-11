/** Route loading options. */
interface LoadOptions {
    /** The actual routes implementation. */
    handlers: any;
    /** The file containing routes to be loaded. */
    filename?: string;
    /** Optional version of the API / routes / swagger. */
    version?: string;
}
/** Routes class (based on plain JSON or Swagger). */
declare class Routes {
    private static _instance;
    /** @hidden */
    static readonly Instance: Routes;
    /** Returns a new fresh instance of the Routes module. */
    newInstance(): Routes;
    /**
     * Load routes from the specified file.
     * @param options Loading options with filename and handlers.
     */
    load: (options: LoadOptions) => void;
    /**
     * Load routes from a swagger definition file.
     * @param options Loading options.
     */
    loadSwagger: (options: LoadOptions) => void;
    /**
     * Add parameters to the request swagger object. Internal use only.
     */
    private castParameter;
}
declare const _default: Routes;
export = _default;
