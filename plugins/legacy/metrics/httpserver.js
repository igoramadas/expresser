/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// METRICS: HTTP SERVER HELPER
// --------------------------------------------------------------------------

/*
 * Helper class to manage the HTTP server exposing the metrics output.
 */
let exports;
var HttpServer = (function() {
    let metrics = undefined;
    let express = undefined;
    let logger = undefined;
    let settings = undefined;
    let webServer = undefined;
    HttpServer = 
    HttpServer.initClass();
    return HttpServer;
})();

// Singleton implementation
// -----------------------------------------------------------------------------
HttpServer.getInstance = function() {
    if ((this.instance == null)) { this.instance = new HttpServer(); }
    return this.instance;
};

module.exports = (exports = HttpServer.getInstance());
