# Expresser: App

**Before you start** make sure to enable the `settings.app.paas` setting in case you're deploying to
AppFog, Heroku, OpenShift or any other PaaS provider. By doing this the all modules will get IP, ports and other PaaS specific settings from environment variables.

The App is the main module of Expresser. It creates a new Express server and set all default options like
session and cookie secrets, paths to static resources, asset bindings etc. By default it will bind to all
local addresses and on port 8080 (when running on your local environment). The Express server is exposed via the {{ server }} property on the App module.

By default it will use Jade as the default template parser. The jade files should be inside the _/views/_
folder on the root of your app.  It will also use Connect Assets and serve all static files from _/public/_.
To change these paths, please edit the {{ settings.path }} keys and values. The client-side JavaScript or CoffeeScript should be inside the _/assets/js/_ folder, and CSS or Stylus should be in _/assets/css/_.

If you're planning to use cookies and/or sessions on your app, please update the {{ settings.app.cookieSecret }} and {{ settings.app.sessionSecret }} with a strong key replacing the default values.

### Adding your own middleware

The built-in Passport (basic HTTP and LDAP authentication) support was removed on version 0.9.0, in favour of a more flexible way of adding your own middlewares to the Express app.

Simply pass them using the {{ extraMiddlewares }} option on [App] init. For example if you're using Passport it should look similar to:
{{
expresser = require "expresser"
passport = require "passport"

// My Passport specific code here...

extraMiddlewares = [passport.initialize(), passport.session()]
expresser.init {extraMiddlewares: extraMiddlewares}
}}

For detailed info on specific features, check the annotated source on /docs folder.
