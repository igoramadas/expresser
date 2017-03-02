# Expresser

A Node.js platform with web, database, email, logging and other special features, built on top of Express.

[![Build Status](https://travis-ci.org/igoramadas/expresser.png?branch=master)](https://travis-ci.org/igoramadas/expresser)
[![Coverage Status](https://coveralls.io/repos/github/igoramadas/expresser/badge.svg?branch=master)](https://coveralls.io/github/igoramadas/expresser?branch=master)

### Why Expresser?

Even if Express itself does a good job as a web application framework, it can still be considered quite "low level"
by some. So the idea of Expresser is to aggregate common modules and utilities into a single package, to make it
even easier to start and streamline your Node.js application. Developed with Coffee-Script.

### Settings

Settings for the app and all modules are loaded by the `settings.coffee` module. If you wish to customize any of
these settings, please create a `settings.json` file on the root of your app folder with the specific keys
and values. For more info please head to https://github.com/igoramadas/expresser/blob/master/docs/settings.md.

### Example app

    expresser = require "expresser"
    logger = expresser.logger
    metrics = require "expresser-metrics"
    settings = expresser.settings
    app = expresser.app

    # Init the app!
    expresser.init()
    logger.info "Server started!"

    # Renders the index.pug view from /views folder
    app.server.get "/", (req, res) -> app.renderView req, res, "index"

    # Renders output from the Metrics plugin.
    app.server.get "/metrics", (req, res) -> app.renderJson req, res, metrics.output()

It seems pretty simple, right? Most configuration is done on the `settings.json` file. Paths, default views,
server port, etc etc...

# Main modules

Now to the main modules...

### App
*   Pre-configured Express web server.
*   https://github.com/igoramadas/expresser/blob/master/docs/app.md

### Events
*   Central events dispatcher.
*   https://github.com/igoramadas/expresser/blob/master/docs/events.md

### Database
*   Supports reading, updating and deleting documents on databases.
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

And the official plugins...

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

### Metrics
*   Generate and report metrics for your application.
*   https://github.com/igoramadas/expresser/tree/master/plugins/metrics

### PaaS
*   Automatically configuration of modules running on PaaS providers.
*   https://github.com/igoramadas/expresser/tree/master/plugins/paas

### Sockets
*   Wrapper for the Socket.IO module.
*   Works even if your server does not support websockets.
*   https://github.com/igoramadas/expresser/tree/master/plugins/sockets

# Need help?

Can't find what you're looking for? Need help? Then post on the Issue Tracker: https://github.com/igoramadas/expresser/issues
