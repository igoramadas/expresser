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
*   Pre-configured Express server with built-in support for some PaaS providers.
*   https://github.com/igoramadas/expresser/blob/master/docs/app.md

### Cron
*   Configurable cron for scheduled tasks using JSON files.
*   Supports multiple files and multiple modules.
*   Supports managing scheduled tasks programatically.
*   Low memory footprint, high performance.
*   https://github.com/igoramadas/expresser/tree/master/plugins/cron

### Database
*   Supports reading, updating and deleting documents on general databases.
*   Plugins for MongoDB and TingoDB databases.
*   https://github.com/igoramadas/expresser/blob/master/docs/database.md
*   https://github.com/igoramadas/expresser/tree/master/plugins/database-mongodb
*   https://github.com/igoramadas/expresser/tree/master/plugins/database-tingodb

### Downloader
*   Configurable download manager supporting standard web protocols.
*   https://github.com/igoramadas/expresser/tree/master/plugins/downloader

### Firewall
*   Automatic protection against SQLi, CSS and LFI attacks.
*   Automatic IP blacklisting.
*   Works on HTTP and Socket connections.
*   https://github.com/igoramadas/expresser/tree/master/plugins/firewall

### Logger
*   Simple info, warn and error logging methods.
*   Plugins for local files, Logentries (http://logentries.com) and Loggly (http://loggly.com).
*   https://github.com/igoramadas/expresser/blob/master/docs/logger.md
*   https://github.com/igoramadas/expresser/tree/master/plugins/logger-logentries
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

### Utils
*   General utilities and helper methods.
*   https://github.com/igoramadas/expresser/blob/master/docs/utils.md

## Running on PaaS

Deploying your Expresser based app to AppFog, Heroku, OpenShift and possibly any other PaaS is dead simple.
No need to configure anything - just leave the `Settings.app.paas` setting on, and it will automatically set
settings from environment variables.

#### I have a problem!

Can't find what you're looking for? Need help? Then post on the Issue Tracker: https://github.com/igoramadas/expresser/issues
