/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// METRICS: PERCENTILE HELPER
// --------------------------------------------------------------------------

/*
 * Helper class to calculate percentiles.
 */

let exports;
var Percentile = (function() {
    let swap = undefined;
    let partition = undefined;
    let findK = undefined;
    Percentile = class Percentile {
        static initClass() {

            swap = function(data, i, j) {
                if (i === j) { return; }

                const tmp = data[j];
                data[j] = data[i];
                return data[i] = tmp;
            };

            partition = function(data, start, end) {
                let i = start + 1;
                let j = start;

                while (i < end) {
                    if (data[i] < data[start]) { swap(data, i, ++j); }
                    i++;
                }

                swap(data, start, j);

                return j;
            };

            findK = function(data, start, end, k) {
                while (start < end) {
                    const pos = partition(data, start, end);

                    if (pos === k) {
                        return data[k];
                    }
                    if (pos > k) {
                        end = pos;
                    } else {
                        start = pos + 1;
                    }
                }

                return null;
            };
        }

        calculate(durations, perc) {
            let result = findK(durations.concat(), 0, durations.length, Math.ceil((durations.length * perc) / 100) - 1);
            if ((result == null) || (result < 0)) { result = 0; }

            return result;
        }
    };
    Percentile.initClass();
    return Percentile;
})();

// Singleton implementation
// -----------------------------------------------------------------------------
Percentile.getInstance = function() {
    if ((this.instance == null)) { this.instance = new Percentile(); }
    return this.instance;
};

module.exports = (exports = Percentile.getInstance());
