/// <reference types="node" />
import EventEmitter = require("eventemitter3");
import express = require("express");
import { Http2SecureServer, Http2Server } from "http2";
/** Middleware definitions to be be passed on app [[init]]. */
interface MiddlewareDefs {
    /** Single or array of middlewares to be prepended. */
    prepend: any | any[];
    /** Single or array of middlewares to be appended. */
    append: any | any[];
}
/** Main App class. */
declare class App {
    private static _instance;
    /** @hidden */
    static readonly Instance: App;
    /** Returns a new fresh instance of the App module. */
    newInstance(): App;
    /** Default App constructor. Binds the [[Logger]] clean by default for logging. */
    constructor();
    /** Express application. */
    expressApp: express.Application;
    /** The underlying HTTP(S) server. */
    server: any;
    /** Event emitter. */
    events: EventEmitter;
    /**
     * Init the app module and start the HTTP(S) server.
     * @param middlewares List of middlewares to be appended / prepended.
     */
    init(middlewares?: MiddlewareDefs): void;
    /**
     * Start the HTTP(S) server.
     * @returns The HTTP(S) server created by Express.
     */
    start(): Http2Server | Http2SecureServer;
    /**
     * Kill the underlying HTTP(S) server(s).
     */
    kill(): void;
    /**
     * Shortcut to express ".all()".
     * @param reqPath The path for which the middleware function is invoked.
     * @param callbacks Single, array or series of middlewares.
     */
    all(reqPath: string | RegExp | any[], ...callbacks: any[]): any;
    /**
     * Shortcut to express ".get()".
     * @param reqPath The path for which the middleware function is invoked.
     * @param callbacks Single, array or series of middlewares.
     */
    get(reqPath: string | RegExp | any[], ...callbacks: any[]): any;
    /**
     * Shortcut to express ".post()".
     * @param reqPath The path for which the middleware function is invoked.
     * @param callbacks Single, array or series of middlewares.
     */
    post(reqPath: string | RegExp | any[], ...callbacks: any[]): any;
    /**
     * Shortcut to express ".put()".
     * @param reqPath The path for which the middleware function is invoked.
     * @param callbacks Single, array or series of middlewares.
     */
    put(reqPath: string | RegExp | any[], ...callbacks: any[]): any;
    /**
     * Shortcut to express ".patch()".
     * @param reqPath The path for which the middleware function is invoked.
     * @param callbacks Single, array or series of middlewares.
     */
    patch(reqPath: string | RegExp | any[], ...callbacks: any[]): any;
    /**
     * Shortcut to express ".delete()".
     * @param reqPath The path for which the middleware function is invoked.
     * @param callbacks Single, array or series of middlewares.
     */
    delete(reqPath: string | RegExp | any[], ...callbacks: any[]): any;
    /**
     * Shortcut to express ".use()".
     * @param reqPath The path for which the middleware function is invoked.
     * @param callbacks Single, array or series of middlewares.
     */
    use(reqPath?: string, ...callbacks: any[]): any;
    /**
     * Shortcut to express ".route()".
     * @param reqPath The path of the desired route.
     * @returns An instance of a single route for the specified path.
     */
    route(reqPath: string): express.IRoute;
    /**
     * Render a view and send to the client. The view engine depends on the settings defined.
     * @param req The Express request object.
     * @param res The Express response object.
     * @param view The view filename.
     * @param options Options passed to the view, optional.
     */
    renderView(req: express.Request, res: express.Response, view: string, options?: any): void;
    /**
     * Sends pure text to the client.
     * @param req The Express request object.
     * @param res The Express response object.
     * @param text The text to be rendered, mandatory.
     */
    renderText: (req: express.Request, res: express.Response, text: any) => void;
    /**
     * Render response as JSON data and send to the client.
     * @param req The Express request object.
     * @param res The Express response object.
     * @param data The JSON data to be sent.
     */
    renderJson: (req: express.Request, res: express.Response, data: any) => void;
    /**
     * Render an image from the speficied file, and send to the client.
     * @param req The Express request object.
     * @param res The Express response object.
     * @param filename The full path to the image file.
     * @param options Options passed to the image renderer, for example the "mimetype".
     */
    renderImage: (req: express.Request, res: express.Response, filename: string, options?: any) => void;
    /**
     * Sends error response as JSON.
     * @param req The Express request object.
     * @param res The Express response object.
     * @param error The error object or message to be sent to the client.
     * @param status The response status code, optional, default is 500.
     */
    renderError: (req: express.Request, res: express.Response, error: any, status?: string | number) => void;
}
declare const _default: App;
export = _default;
