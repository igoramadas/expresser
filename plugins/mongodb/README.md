# Expresser: MongoDB Database

The Database module is a MongoDB wrapper and has 3 main methods: {{ get }}, {{ set }} and {{ del }}. There's also a {{ count }} helper that works with newer versions of MongoDB.

If the {{ settings.app.cloud }} setting is enabled, the Database module will automatically figure out the connection details for the following MongoDB services: AppFog, MongoLab, MongoHQ.

### Sample code

The following example illustrates how to get a document having "username = igor" from collection "users" and duplicate
it to a document having "username = igor2". Errors will be logged using the Logger module.

    var expresser = require("expresser");

    var setCallback = function (err, result) {
        if (err) {
            expresser.logger.error("Can't save document with username igor2.", err);
        } else {
            expresser.logger.info("Document duplicated!", result);
        }
    }

    var getCallback = function (err, result) {
        if (err) {
            expresser.logger.error("Can't get document with username igor.", err);
        } else {
            user = result[0];
            user.username = "igor2"; // Update the username 'igor' to 'igor2'.
            delete user["id"]; // Delete the user ID so it's created as a new document.
            expresser.database.set("users", user, setCallback);
        }
    }

    expresser.database.mongo.get("users", {username: "igor"}, getCallback);

---

*For detailed info on specific features, check the annotated source on /docs/database-mongo.html*
