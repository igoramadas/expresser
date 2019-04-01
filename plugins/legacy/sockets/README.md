# Expresser Sockets

The Sockets module is a wrapper for Socket.IO, handled automatically by the App module. If you want to disable it, set
`settings.sockets.enabled` to false. For more details about Socket.IO, go to http://socket.io.

### Sample code

The sample below shows how to emit a test message to all clients, and listen to a "form:submit" event.

    var expresser = require("expresser")

    expresser.sockets.emit("myevent", {message: "This is a test"})
    expresser.sockets.on("form:submit", function(formData) {
        console.log(formData)
    })

For detailed info on specific features, check the annotated source on /docs folder.
