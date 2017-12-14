# Expresser

A Node.js framework with web server, events, logging and other common utilities, built on top of Express.js.

[![Build Status](https://travis-ci.org/igoramadas/expresser.png?branch=master)](https://travis-ci.org/igoramadas/expresser)
[![Coverage Status](https://coveralls.io/repos/github/igoramadas/expresser/badge.svg?branch=master)](https://coveralls.io/github/igoramadas/expresser?branch=master)

### Why Expresser?

The idea of Expresser is to aggregate common modules and utilities into a single package, making it damn easy
to start and streamline your new Node.js application. Developed with CoffeeScript v2, it has full support for all
the new features of ES6, including async / await.

### Use Expresser if...

* You're new to Node.js web apps
* You're familiar with Express.js
* You want to use a similar codebase on your Node.js apps

### Look elsewhere if...

* You hate CoffeeScript
* You hate Express.js
* You need ultimate performance and as little overhead as possible (in this case you should not be using many external packages anyways)

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

It seems pretty simple, right? Most configuration is done on a `settings.json` file...

### Settings

Settings for the app and all modules are loaded by the `settings.coffee` module. If you wish to customize any of
these settings, please create a `settings.json` file on the root of your app folder with the specific keys
and values. For more info please head to https://github.com/igoramadas/expresser/blob/master/docs/settings.md.

# Main modules

Now to the main modules...

### App
*   Pre-configured Express web server.
*   https://expresser.devv.com/guides/App.html

### Events
*   Central events dispatcher.
*   https://expresser.devv.com/guides/Events.html

### Logger
*   Application logging.
*   https://expresser.devv.com/guides/Logger.html

### Settings
*   Settings wrapper.
*   https://expresser.devv.com/guides/Settings.html

### Utils
*   General utilities and helper methods.
*   https://expresser.devv.com/guides/Utils.html

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
*   MongoDB database wrapper.
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
*   Wrapper around Nodemailer, with support for SMTP and a bunch of email services.
*   Supports email templates and keywords parsing.
*   https://github.com/igoramadas/expresser/tree/master/plugins/mailer

### Metrics
*   Generate and report metrics for your application.
*   https://github.com/igoramadas/expresser/tree/master/plugins/metrics

### Sockets
*   Wrapper for the Socket.IO module.
*   https://github.com/igoramadas/expresser/tree/master/plugins/sockets

# Need help?

Can't find what you're looking for? Need help? Then post on the Issue Tracker: https://github.com/igoramadas/expresser/issues
