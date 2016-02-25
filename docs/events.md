# Expresser: Events

Expresser implements a central event dispatcher which is used internally between its various modules and can also be used by your application to fire and listen to events.

To listen please use the {{ events.on }} method, passing the key and the callback. To stop listening, use {{ events.off }} passing the key and callback as well. To emit an event, use {{ events.emit }} passing the event name and its data / arguments.

For detailed info on specific features, check the annotated source on /docs folder.
