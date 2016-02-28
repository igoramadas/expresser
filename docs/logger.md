# Expresser: Logger

The Logger module provides integrated logging functionality to your app. By default it supports only console logging
but you can add additional transports via plugins (for example logger-file, logger-logentries and logger-loddly).

### Log types

At the moment the Logger offers 4 default log types: info, warn, error and critical. These methods support N number
of arguments, which will be parsed and transformed to a single log line.

For example to log an exception:

    expresser = require "expresser"
    
    try
        mymodule.doSomethingWrong()
    catch ex
        expresser.logger.error "My method", "Some description", ex

### Using Logentries

Create an account on Logentries. Then register your host, and create a default log for this host. You should then get the "Token" for this log, and change the Logentries token key:

    "logger": { 
        "logentries": {
            "enabled": true,
            "token": "your-logentries-token-here"
        }
    }

### Using Loggly

Create an account on Loggly. Then register your host, and create a default log for this host. You should then get the "Token" for this log, and change the Loggly token and subdomain keys:

    "logger": { 
        "loggly": {
            "enabled": true,
            "subdomain": "my-subdomain",
            "token": "your-loggly-token-here"
        }
    }

### Logging unhandled exceptions

If you want to log unhandled exceptions (thrown at process level), set {{ settings.logger.uncaughtException }} to true (it is true by default!) and the Logger will save the stack trace to the errors log.

### Using multiple transports

You can have any combination of transports enabled at the same time. For example Local and Logentries, or Logentries and Loggly.

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
