# Logger

The Logger module provides integrated logging functionality to your app. By default it supports only console logging
but you can add additional transports via plugins (for example logger-file, logger-logentries and logger-loggly).

### Basic usage

    var myModule = require("my-custom-module")
    var expresser = require("expresser")
    var logger = expresser.logger

    logger.debug("ExampleModule", myModule.stats())
    logger.info("Log Title", "Some info here...", someVariable, "More info...")

    if (somethingNotSecure) {
        logger.warn("Oops", "Something is not secure...")
    }

    try {
        myModule.doSomethingWrong()
    } catch (ex) {
        logger.error("MyModule", ex)
    }

    var logLine = logger.info("All logger methods always return the full parsed string / log line")

### Log types

At the moment the Logger offers 4 default log types: info, warn, error and critical. These methods support N number
of arguments, which will be parsed and transformed to a single log line.

### Styling the console logs

The Logger makes use of Chalk to set colours and font styles on the console output.
The default styles are set under the `settings.logger.styles` setting. For more info
please head to https://github.com/chalk/chalk.

### Logging unhandled exceptions

By default the Logger module will log all unhandled exceptions as error. If you want to disable that, please set
the `settings.logger.uncaughtException` to false.

### Using multiple transports

You can have multiple transports enabled at the same time, and also log only to specific transports by directly
targeting then on your code.

### Listening to log events

The Logger module exposes a `logSuccess` and `logError` events, triggered for every (un)successful log. This is
useful in case you want to do a post-operation on logs (for example increment a counter) or to have a fallback
solution in case your log transport is down.

    var expresser = require("expresser")
    var counter = 0

    var mySuccessFunction = function (transport, data) {
        counter++
    }

    var myErrorFunction = function (transport, error) {
        console.warn("Not logged!", transport, data)
    }

    expresser.logger.on("logSuccess", mySuccessFunction)
    expresser.logger.on("logError", myErrorFunction)

Use `expresser.logger.off` to stop listeting to these logging events. For example:

    expresser.logger.off("logSuccess", mySuccessFunction)
    expresser.logger.off("logError", myErrorFunction)

---

*For detailed info on specific features, check the annotated source on /docs/source/logger.html*