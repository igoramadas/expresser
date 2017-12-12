# Expresser

A Node.js framework with built-in web server, logging and other common utilities, built on top of Express.

[![Build Status](https://travis-ci.org/igoramadas/expresser.png?branch=master)](https://travis-ci.org/igoramadas/expresser)
[![Coverage Status](https://coveralls.io/repos/github/igoramadas/expresser/badge.svg?branch=master)](https://coveralls.io/github/igoramadas/expresser?branch=master)

### Why Expresser?

The idea of Expresser is to aggregate common modules and utilities into a single package, making it damn easy
to start and streamline your Node.js application. Developed with CoffeeScript v2, it has full support for all
the new features of ES6, including async / await.

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

    # Init the Expresser framework
    expresser.init()
    logger.info "App started!"

    # Renders the index.pug view from /views folder
    app.server.get "/", (req, res) -> app.renderView req, res, "index"

    # Renders output from the Metrics plugin.
    app.server.get "/metrics", (req, res) -> app.renderJson req, res, metrics.output()

It seems pretty simple, right? Most configuration is done on the `settings.json` file. Paths, default views,
server port, etc...

# Main modules

Now to the main modules...

### App
*   Pre-configured Express web server.
*   https://github.com/igoramadas/expresser/wiki/App

### Events
*   Central events dispatcher.
*   https://github.com/igoramadas/expresser/wiki/Events

### Logger
*   Application logging.
*   https://github.com/igoramadas/expresser/wiki/Logger

### Settings
*   Settings wrapper.
*   https://github.com/igoramadas/expresser/wiki/Settings

### Utils
*   General utilities and helper methods.
*   https://github.com/igoramadas/expresser/wiki/Utils

# Plugins

And the official plugins...

### AWS
*   Wrapper around some of the AWS SDK features.
*   https://github.com/igoramadas/expresser/tree/master/plugins/aws

### Cron
*   Configurable cron for scheduled tasks using JSON files.
*   Supports multiple files and multiple modules.
*   Supports managing scheduled tasks programatically.
*   https://github.com/igoramadas/expresser/tree/master/plugins/cron

### Database: MongoDB
*   MongoDB driver for the Database module.
*   https://github.com/igoramadas/expresser/tree/master/plugins/database-mongodb

### Downloader
*   Configurable download manager supporting standard web protocols.
*   https://github.com/igoramadas/expresser/tree/master/plugins/downloader

### Google Cloud
*   Wrapper around some of the Google Cloud SDK features.
*   https://github.com/igoramadas/expresser/tree/master/plugins/gcloud

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

### Sockets
*   Wrapper for the Socket.IO module.
*   Works even if your server does not support websockets.
*   https://github.com/igoramadas/expresser/tree/master/plugins/sockets

# Need help?

Can't find what you're looking for? Need help? Then post on the Issue Tracker: https://github.com/igoramadas/expresser/issues
