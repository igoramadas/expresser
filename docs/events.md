# Expresser: Events

This is the central event dispatcher for all of Expresser's modules and plugins. You can extend and use it
also for your own custom events.

To listen please use the `events.on` method, passing the key and the callback. To stop listening,
use `events.off` passing the key and callback as well. To emit an event, use `events.emit` passing the
event name and its data / arguments. For example:

    var expresser = require("expresser");
    var events = expresser.events;
    
    // Listen to something...
    logToConsole (message) = function() {console.log "My class says...", message}
    events.on("MyClass.saySomething", logToConsole);
    
    // Display "Hey ho let's go" on the console...
    events.emit("MyClass.saySomething", "Hey ho let's go");
    
    

As this is simply a wrapper around Node.js Events class, you can read more at https://nodejs.org/api/events.html.

---

*For detailed info on specific features, check the annotated source on /docs/events.html*
