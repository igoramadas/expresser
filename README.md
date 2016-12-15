# Expresser

A Node.js platform with web, database, email, logging, twitter and firewall features, built on top of Express.
Official project page: http://github.com/igoramadas/expresser

[![Build Status](https://travis-ci.org/igoramadas/expresser.png?branch=master)](https://travis-ci.org/igoramadas/expresser)
[![Coverage Status](https://coveralls.io/repos/github/igoramadas/expresser/badge.svg?branch=master)](https://coveralls.io/github/igoramadas/expresser?branch=master)

### Why Expresser?

Even if Express itself does a good job as a web application framework, it can still be considered low level.
So the idea of Expresser is to aggregate common modules and utils into a single package, and make it even easier to
start your Node.js web app.

### How to configure

Settings for the app and all modules are loaded by the `settings.coffee` module. If you wish to customize any of
these settings, please create a `settings.json` file on the root of your app folder with the specific keys
and values. Detailed instructions are available on the top of the `settings.coffee` file.

You can also change settings directly on runtime, via the `settings` property of Expresser, for example:

    var expresser = require("expresser");
    expresser.settings.app.title = "My App";
    expresser.settings.myStuff = 123;

More info can be found at https://github.com/igoramadas/expresser/blob/master/docs/settings.md.

# Main modules

Below you'll find important information about each of Expresser modules. Detailed documentation is extracted from
the source code and available under the `/docs/` folder.

### App
*   Pre-configured Express web server.
*   https://github.com/igoramadas/expresser/blob/master/docs/app.md

### Events
*   Central events dispatcher.
*   https://github.com/igoramadas/expresser/blob/master/docs/events.md

### Database
*   Supports reading, updating and deleting documents on general databases.
*   https://github.com/igoramadas/expresser/blob/master/docs/database.md

### Logger
*   Simple info, warn and error logging methods.
*   https://github.com/igoramadas/expresser/blob/master/docs/logger.md

### Settings
*   Settings wrapper.
*   https://github.com/igoramadas/expresser/blob/master/docs/settings.md

### Utils
*   General utilities and helper methods.
*   https://github.com/igoramadas/expresser/blob/master/docs/utils.md

# Plugins

And the official plugins:

### Cron
*   Configurable cron for scheduled tasks using JSON files.
*   Supports multiple files and multiple modules.
*   Supports managing scheduled tasks programatically.
*   https://github.com/igoramadas/expresser/tree/master/plugins/cron

### Database: MongoDB
*   MongoDB driver for the Database module.
*   https://github.com/igoramadas/expresser/tree/master/plugins/database-mongodb

### Database: TingoDB
*   TingoDB driver for the Database module.
*   https://github.com/igoramadas/expresser/tree/master/plugins/database-tingodb

### Downloader
*   Configurable download manager supporting standard web protocols.
*   https://github.com/igoramadas/expresser/tree/master/plugins/downloader

### Logger: File
*   Local file driver for the Logger module.
*   https://github.com/igoramadas/expresser/tree/master/plugins/logger-file

### Logger: Logentries
*   Logentries (http://logentries.com) driver for the Logger module.
*   https://github.com/igoramadas/expresser/tree/master/plugins/logger-logentries

### Logger: Loggly
*   Loggly (http://loggly.com) for the Logger module.
*   https://github.com/igoramadas/expresser/tree/master/plugins/logger-loggly

### Mailer
*   Supports sending emails via SMTP using optional authentication and SSL/TLS.
*   Supports email templates and keywords.
*   Automatic switching to a failover SMTP server in case the main one fails to send.
*   https://github.com/igoramadas/expresser/tree/master/plugins/mailer

### Sockets
*   Wrapper for the Socket.IO module.
*   Works even if your server does not support websockets.
*   https://github.com/igoramadas/expresser/tree/master/plugins/sockets

## Running on PaaS

Deploying your Expresser based app to AppFog, Heroku, OpenShift and possibly any other PaaS is dead simple.
No need to configure anything - just leave the `Settings.app.paas` setting on, and it will automatically set
settings from environment variables.

#### I have a problem!

Can't find what you're looking for? Need help? Then post on the Issue Tracker: https://github.com/igoramadas/expresser/issues
