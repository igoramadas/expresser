/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// EXPRESSER METRICS
// --------------------------------------------------------------------------
let exports;
const percentile = require("./percentile.coffee");




// This is where we store all metrics.
const metrics = {};

// Timer to cleanup metrics.
let cleanupTimer = null;


Metrics.initClass();

// Singleton implementation
// -----------------------------------------------------------------------------
Metrics.getInstance = function() {
    if ((this.instance == null)) { this.instance = new Metrics(); }
    return this.instance;
};

module.exports = (exports = Metrics.getInstance());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
