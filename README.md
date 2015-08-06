# Expresser

A Node.js platform with web, database, email, logging, twitter and firewall features, built on top of Express.
Official project page: http://github.com/igoramadas/expresser

[![Build Status](https://travis-ci.org/igoramadas/expresser.png?branch=master)](https://travis-ci.org/igoramadas/expresser)


### Why Expresser?

Even if Express itself does a good job as a web application framework, it can still be considered low level.
So the idea of Expresser is to aggregate common modules and utils into a single package, and make it even easier to
start your Node.js web app.


### How to configure

All settings for all modules are wrapped on the `settings.coffee` file. If you wish to customize any of
these settings, please create a `settings.json` file on the root of your app folder with the specific keys
and values. Detailed instructions are available on the top of the `settings.coffee` file.

You can also change settings directly on runtime, via the `settings` property of Expresser, for example:

    require("expresser").settings.app.title = "My App".

More info can be found at https://github.com/igoramadas/expresser/wikipage?title=Settings


## Modules

Below you'll find important information about each of Expresser modules. Detailed documentation is extracted from
the source code and available under the `/docs/` folder.


### App
*   Pre-configured Express server ready to run on most PaaS providers.

More info at https://github.com/igoramadas/expresser/wikipage?title=App


### Database
*   Supports reading, updating and deleting documents on MongoDB databases.
*   Automatic switching to a failover database in case the main one is down.

More info at https://github.com/igoramadas/expresser/wikipage?title=Database


### Firewall
*   Automatic protection against SQLi, CSS and LFI attacks.
*   Automatic IP blacklisting.
*   Works on HTTP and Socket connections.

More info at https://github.com/igoramadas/expresser/wikipage?title=Firewall


### Imaging
*   Wrapper for ImageMagick.
*   Easy conversion between multiple image types.

More info at https://github.com/igoramadas/expresser/wikipage?title=Imaging


### Logger
*   Simple info, warn and error logging methods.
*   Suppports logging to local files, Logentries (http://logentries.com) and Loggly (http://loggly.com).

More info at https://github.com/igoramadas/expresser/wikipage?title=Logger


### Mail
*   Supports sending emails via SMTP using optional authentication and SSL/TLS.
*   Supports email templates and keywords.
*   Automatic switching to a failover SMTP server in case the main one fails to send.

More info at https://github.com/igoramadas/expresser/wikipage?title=Mail


### Sockets
*   Wrapper for the Socket.IO module.
*   Works even if your server does not support websockets.

More info at https://github.com/igoramadas/expresser/wikipage?title=Sockets


### Utils
*   General utilities and helper methods.

More info at https://github.com/igoramadas/expresser/wikipage?title=Utils


## Running on PaaS

Deploying your Expresser based app to AppFog, Heroku, OpenShift and possibly any other PaaS is dead simple.
No need to configure anything - just leave the `Settings.app.paas` setting on, and it will automatically set
settings from environment variables.


## Common questions and answers

#### Where is this project hosted?

The official project page is at CodePlex: http://github.com/igoramadas/expresser. But as we know there are lots of people
who prefer GitHub, there's a remote repo at GitHub as well: https://github.com/igoramadas/expresser.

#### How can I change specific settings without touching the `settings.coffee` file?

Create a `settings.json` file with the specific keys and values that you want to override. For example:

    {
        "general": {
            "appTitle": "My App"
        },
        "app": {
            "paas": false,
            "port": 1234
        }
    }

You can also change settings programatically:

    var expresser = require("expresser");
    expresser.settings.app.title = "MyApp";

#### I have a problem!

Can't find what you're looking for? Need help? Then post on the Issue Tracker: http://github.com/igoramadas/expresser/workitem/list/basic
