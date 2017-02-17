# Expresser Metrics

Plugin to gather and output simple metrics on Expresser apps.

### Adding and using metrics

To measure something:

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

    metrics.cleanup();

### Output

To generate a summary about collected metrics, use the built-in output method:

    var output = metrics.output();

    // Some code...

    res.render(output);

By default it will give you the specific metrics for the last 1min, 5min and 30min,
having the 99, 98 and 95 percentiles. You can change these values on the settings.
