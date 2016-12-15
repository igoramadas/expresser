# Expresser: Settings

#### Filename: settings.coffee

This module holds all settings for all modules of Expresser and its relevant plugins. I can also be extended
to include your own custom settings.

The `settings.default.json` file is commented with all Expresser settings. Please check it for detailed instructions.

## How to define and use the settings

You can define your own settings in 3 different ways:

#### Creating a *settings.json* or *settings.NODE_ENV.json* file on the root of your application.

Please note that when you call the main `expresser.init()`, it will automatically look for the
`settings.json` and `settings.NODE_ENV.json` files and auto load them. So you don't need to do
this manually.

#### Using the `loadFromJson` helper method passing the path to your custom settings file.

Alternativelly you might want to load settings on demand, by calling the `loadFromJson` method manually.
For example to load from the `mysettings.json` file:

    var expresser = require("expresser");
    expresser.settings.loadFromJson("mysettings.json");

#### Programmatically on your app code by doing `expresser.settings.some.else = mystuff`.

Defining your settings programatically is quite simple:

    var expresser = require("expresser");
    expresser.settings.app.title = "New Title";
    expresser.settings.someNewStuff = {
        somevalue: true,
        timestamp: new Date()
    };

## Per-environment settings

You can define specific settings for specific environments by using `settings.NODE_ENV.json` files.
For example `settings.development.json` will be loaded only on development and `settings.mydeployment.json`
will be loaded only on mydeployment.

## Strategy for temporary or local-only settings

If you wish to have settings that apply only to your development machine, we suggest you to create a file
`settings.local.json` and load it programatically on your app code. Then you can add that file to your
`.gitignore` (or equivalent) to avoid having it pushed to the source control, docker and other machines.
For example your `index.js` could have something like:

    var expresser = require("expresser");
    
    // Load local settings and start the Expresser app.
    expresser.settings.loadFromJson("settings.local.json");
    expresser.init(settings);

    myApp.init();
    myApp.doSomething();
    
    // Some more app init code here...

## Encrypting the settings files

The settings class comes with a built-in encryption helper. You can define the encryption key either
programatically or using the EXPRESSER_SETTINGS_CRYPTOKEY environment variable.

### To encrypt

Using the defaults and the key set on the EXPRESSER_SETTINGS_CRYPTOKEY environment variable:

    var expresser = require("expresser");
    expresser.settings.encrypt("settings.json");

Encrypt the production settings using a custom cipher and key:

    var expresser = require("expresser");
    expresser.settings.encrypt("settings.production.json", {cipher: "aes512", key: "My Key"});

### To decrypt

Same procedure of encryption, but using the `decrypt` method:

    var expresser = require("expresser");
    expresser.settings.decrypt("settings.json");

## Resetting to default settings

The `settings.reset()` method will create a new instance and reset all settings to their default initial state.
Custom values set programmatically will be cleared out.

---

*For detailed info on specific features, check the annotated source on /docs/source/settings.html*
