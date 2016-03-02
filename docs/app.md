# Expresser: App

This is the core of any Expresser app, and holds the HTTP(s) server along session and cookie secrets, paths to
static resources, asset bindings etc. By default it will bind to all local addresses on port 8080 (when running
on your local environment). The Express server is exposed via the `server` property on the App module.

### Before you start

Make sure to enable the `settings.app.paas` setting in case you're deploying to Heroku, 
OpenShift or any other PaaS provider. By doing this the all modules will get IP, ports and other PaaS specific
settings from environment variables.

### Cookies and sessions

If you're planning to use cookies and/or sessions on your app, please update the `settings.app.cookieSecret` and
`settings.app.sessionSecret` with a strong key replacing the default values.

### Adding your own middleware

You can bind your own middlewares to the Express server by passing them as an option `extraMiddlewares` on
the main `init()` call. For example to use the `passport` middleware:

    var expresser = require("expresser");
    var passport = require("passport");
    
    // Pass my custom middleware to the app.    
    var middlewares = [passport.initialize(), passport.session()];
    expresser.init({extraMiddlewares: middlewares});
    
### Rendering / sending the response to the clients

The App module has some helper methods to send the response to the browser using different formats. They are:

#### renderView(req, res, view, options)

Renders a view (by default it uses Jade) with options.

### renderJson(req, res, data)

Sends JSON data to the client.

---

*For detailed info on specific features, check the annotated source on /docs folder.*
