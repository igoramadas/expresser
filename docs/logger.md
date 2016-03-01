# Expresser: Logger

The Logger module provides integrated logging functionality to your app. By default it supports only console logging
but you can add additional transports via plugins (for example logger-file, logger-logentries and logger-loddly).

### Log types

At the moment the Logger offers 4 default log types: info, warn, error and critical. These methods support N number
of arguments, which will be parsed and transformed to a single log line.

For example to log an exception as "error":

    expresser = require "expresser"
    
    try
        mymodule.doSomethingWrong()
    catch ex
        expresser.logger.error "My method", "Some description", ex

### Logging unhandled exceptions

By default the Logger module will log all unhandled exceptions as error. If you want to disable that, please set
the `settings.logger.uncaughtException` to false.

### Using multiple transports

You can have multiple transports enabled at the same time, and also log only to specific transports by directly
targeting then on your code.

### Listening to log events

The Logger module exposes a {{ logSuccess }} and a {{ logError }} which are triggered for every (un)successful log. For example:

    expresser = require "expresser"
    
    mySuccessFunction = (transport, data) ->
        console.log "Logged successfully!", transport, data
    
    myErrorFunction = (transport, error) ->
        console.warn "Not logged!", transport, data
    
    expresser.logger.on "logSuccess", mySuccessFunction
    expresser.logger.on "logError", myErrorFunction

Use `expresser.logger.off` to stop listening. For example:

    expresser.logger.off "logSuccess", mySuccessFunction

### Automatic email alerts for critical logs

If you define an email on {{ settings.logger.criticalEmailTo }} and the [Mailer] module is correctly configured, the Logger will send an email for every critical log call. To avoid repeated emails, you can define an expiry time for critical alerts on the setting {{ criticalEmailExpireMinutes }}.

---

*For detailed info on specific features, check the annotated source on /docs folder.*
