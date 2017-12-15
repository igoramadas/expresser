# Events

This is the central event dispatcher for all of Expresser's modules and plugins. You can extend and use it
also for your own custom events.

To listen please use the `events.on` method, passing the key and the callback. To stop listening,
use `events.off` passing the key and callback as well. To emit an event, use `events.emit` passing the
event name and its data / arguments. For example:

    var expresser = require("expresser")
    var events = expresser.events

    // Listen to something...
    logToConsole (message) = function() {console.log "My class says...", message}
    events.on("MyClass.saySomething", logToConsole)

    // Display "Hey ho let's go" on the console...
    events.emit("MyClass.saySomething", "Hey ho let's go")

As this is simply a wrapper around Node.js Events class, you can read more at https://nodejs.org/api/events.html.

## Default init events

All modules (and official plugins) of Expresser will emit a few default events, in case you want to coordinate
your app step by step based on module initialization.

- module.before.init: emitted right before the initialization code of the module.
- module.on.init: emitted right after the initialization code of the module.

Please note that the `init` method will delete itself once called!

---
