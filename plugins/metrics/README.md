# Expresser Metrics

Plugin to gather and output simple metrics on Expresser apps.

### Adding and using metrics

First create a metric:

    var mt = metrics.start("metrics-id", someData);

    // Do something here and there... call stuf... finally:

    metrics.end(mt, optionalError);


### Metrics cleanup

By default the module will keep all metrics data for the past 12 hours.
Older data will be purged every 20 minutes automatically. Both values
are customizable on the settings.

If you wish to cleanup manually, simply call:

    metrics.cleanup();

### Output

To generate a summary about collected metrics, use the built-in output method:

    var output = metrics.output();

By default it will give you the specific metrics for the last 1min, 5min and 30min.
You can change the intervals on the settings.
