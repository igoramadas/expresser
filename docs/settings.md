# Expresser: Settings

This class holds all settings for all modules of Expresser and its relevant plugins. I can also be extended
and include your own custom settings.

The *settings.default.json* file is commented with all Expresser settings. Please check it for detailed instructions.

### How to overwrite settings

You can overwrite settings in 3 different ways:

* by creating a *settings.json* or *settings.NODE_ENV.json* file on the root of your application.
* by using the `loadFromJson` helper method passing the path to your custom settings file.
* programmatically on your app code by doing `settings.some.else = mystuff`.

Please note that when you call the main [url:expresser.init()|https://expresser.codeplex.com/SourceControl/latest#lib/expresser.coffee], it will automatically look for the {{ settings.json }} file and use it to override your app settings, so you don't need to do this manually.

Also remember that the Settings class is singleton: if you update a specific setting somewhere, it will reflect on all other parts of your application.

### Per-environment settings

You can define specific settings for specific environments by using `settings.NODE_ENV.json` files.
For example `settings.development.json` will be loaded only on development and `settings.mydeploy.json`
will be loaded only on mydeploy.

### Strategy for temporary or local-only settings

If you wish to have settings that apply only to your development machine, we suggest you to create a file
*settings.local.json* and load it programatically on your app code. Then you can add that file to your
*.gitignore* (or equivalent) to avoid having it pushed to the source control, docker and other machines.
For example your *index.coffee* could look like:

    expresser = require "expresser"
    
    # Load local settings and start the Expresser app.
    expresser.settings.loadFromJson "settings.local.json"
    expresser.init settings

    myApp.init()
    myApp.doSomething()
    
    # Some more app init code here...

### Appending custom settings to the Settings class

You can add as many custom settings as you want and use the Settings class as the main settings repository
for your app, as long as you make sure that there are no conflicts between your custom settings keys and
the ones used by Expresser. For example you could add the following "theme" block to the `settings.json`:

    {
        "theme": {
            "name": "MyTheme:,
            "location": "/mytheme/",
            "colours": ["green", "white", "black"]
        },
    }

The above theme name "MyTheme" for example can be accessed via `expresser.settings.theme.name`, and colour
black is at `expresser.settings.theme.colours[2]`.

### Resetting to default settings

The `settings.reset()` method will create a new instance and reset all settings to their default initial state.
Custom values set programmatically will be cleared out.

---

*For detailed info on specific features, check the annotated source on /docs folder.*
