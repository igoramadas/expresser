# Expresser Metrics

Plugin to gather and output simple metrics on Expresser apps.

### Adding and using metrics

To measure something:

    var metrics = require("expresser-metrics");
    var mt = metrics.start("metrics-id", data);

    // Do something here and there... call stuff..
    // Some more code, async, etc... then finally:

    metrics.end(mt, optionalError);

The ID can be any string. But if you want to query the metrics output using
using string JSON parsers, you should only use valid alphanumerical characters.
The second argument (data) is optional.

### Metrics cleanup

By default the module will keep all metrics data for the past 12 hours.
Older data will be purged every 20 minutes automatically. Both values
are customizable on the settings.

If you wish to cleanup manually, simply call:

    var metrics = require("expresser-metrics");
    metrics.cleanup();

### Output

To generate a summary about collected metrics, use the built-in output method:

    var metrics = require("expresser-metrics");
    var output = metrics.output();

    // Some code...

    res.render(output);

By default it will give you the specific metrics for the last 1min, 5min and 30min,
having the 99, 98 and 95 percentiles. You can change these values on the settings.

You can also generate the output with your own custom options. For example to get
metrics for last 5, 20 and 60 minutes, and not showing the percentiles:

    var options = {
        intervals: [5, 20, 60],
        percentiles: []
    };

    var metrics = require("expresser-metrics");
    var output = metrics.output(options);

And to get metrics for a specific call only:

    function myCall() {
        var mt = metrics.start("my-call");
        // Some code, then end metrics somewhere...
    }

    var options = {
        keys: ["my-call"];
    };

    var metrics = require("expresser-metrics");
    var output = metrics.output(options);

### Metrics HTTP server

The Metrics module can spin up a dedicated HTTP server for the metrics output,
which makes it easier for you to set firewall rules for external access.

To enable the HTTP server, simply add a valid port number to `settings.metrics.httpServer.port`
and set `settings.metrics.httpServer.autoStart` to true.

If you want to control the Metrics HTTP server manually, please set the port programatically
and use the `start` and `kill` methods. You can also access the underlying Express server,
by using the `metrics.httpServer.server` object. For example:

    // Some code, my app starting...

    var expresser = require("expresser");
    var metrics = require("expresser-metrics");

    expresser.settings.metrics.httpServer.port = 8080;
    metrics.httpServer.start();

    // Server started, add a custom route to the metrics http server
    metrics.httpServer.server.get("/my-route", myRouteCallback);

    // More custom stuff... now to kill:

    metrics.httpServer.kill();

---

*For detailed info on specific features, check the annotated source on /docs/source/plugin.metrics.index.html*
