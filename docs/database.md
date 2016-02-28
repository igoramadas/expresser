# Expresser: Database

The Database module is a MongoDB wrapper and has 3 main methods: {{ get }}, {{ set }} and {{ del }}. There's also a {{ count }} helper that works with newer versions of MongoDB.

It also provides a super simple failover mechanism to switch to a backup database in case the main
database fails repeatedly. This will be activated only if you set the {{ settings.database.connString2 }} value. Please note that Expresser won't keep the main and backup database in sync! If you wish to keep them in sync you'll have to implement this feature yourself - we suggest using background workers with IronWorker ([url:http://iron.io]).

If the {{ settings.app.paas }} setting is enabled, the Database module will automatically figure out the connection details for the following MongoDB services: AppFog, MongoLab, MongoHQ.

If you're using Backbone.js or any other framework which uses "id" as the document identifier, you might want to leave the {{ settings.database.normalizeId }} true, so the Database module will parse results and convert {""_id""} to "id" on output documents and from "id" to {""_id""} when saving documents to the db.

### Sample code

The following example illustrates how to get a document having "username = igor" from collection "users" and duplicate it to a document having "username = igor2". Errors will be logged using the Logger module.

    expresser = require "expresser"

    setCallback = (err, result) ->
        if err
            expresser.logger.error 'Can\'t save document with username igor2.', err
        else
            expresser.logger.info 'Document duplicated!', result
        return
    
    getCallback = (err, result) ->
        if err
            expresser.logger.error 'Can\'t get document with username igor.', err
        else
            user = result[0]
            user.username = 'igor2'
            delete user['id']
            expresser.database.set 'users', user, setCallback
        return
    
    expresser.database.get 'users', { username: 'igor' }, getCallback

---

*For detailed info on specific features, check the annotated source on /docs folder.*
