# Expresser

A Node.js platform with web, database, email, logging, twitter and firewall features, built on top of Express.
Available at http://expresser.codeplex.com

### Why Expresser?

Even if Express itself does a good job as a web application framework, it can still be considered low level.
So the idea of Expresser is to aggregate common modules and utils into a single package, and make it even easier to
start your Node.js web app.

### How to configure

All settings for all modules are wrapped on the `settings.coffee` file. If you wish to customize any of
these settings, please create a `settings.json` file on the root of your app folder with the specific keys
and values. Detailed instructions are available on the top / header of the `settings.coffee` file.

## Modules

Below you'll find important information about each of Expresser modules. Detailed documentation is extracted from
the source code and available under the `/docs/` folder.

### App
*   Pre-configured Express server ready to run on most PaaS providers.
*   Built-in support and automatic setup of New Relic (http://newrelic.com)  agent.

**Before you start** make sure to enable the `Settings.App.paas` option in case you're deploying to
AppFog, Heroku, OpenShift or any other PaaS provider. By doing this the App will get IP, ports and
other modules settings based on the process environment variables.

The App is the main module of Expresser. It creates a new Express server and set all default options like
session and cookie secrets, paths to static resources, assets bindings etc.

By default it will use Jade as the default template parser. The jade files should be inside the `/views/`
folder on the root of your app.  It will also use Connect Assets and serve all static files from `/public/`.
To change these paths, please edit the `Settings.Path` keys and values. The client-side JavaScript or CoffeeScript
should be inside the `/assets/js/` folder, and CSS or Stylus should be in `/assets/css/`.

The Express server is exposed via the `server` property on the App module.

To enable New Relic on the server, set the `Settings.NewRelic.appName` and `settings.NewRelic.licenseKey` values
or the `NEW_RELIC_APP_NAME` and `NEW_RELIC_LICENSE_KEY` environment variables. Detailed info can be found
inside the App module source code.

### Database
*   Supports reading, updating and deleting documents on MongoDB servers.
*   Automatic switching to a failover database in case the main one is down.

Expresser provides a super simple failover mechanism that will switch to a backup database in case the main
database fails repeatedly. This will be activated only if you set the `Settings.Database.connString2` value.
Please note that Expresser won't keep the main and backup database in sync! If you wish to keep them in sync
you'll have to implement this feature yourself - we suggest using background workers with IronWorker: http://iron.io.

If the `Settings.App.paas` setting is enabled, the Database module will automatically figure out the connection details for
the following MongoDB services: AppFog, MongoLab, MongoHQ.

### Firewall
*   Automatic protection against SQLi, CSS and LFI attacks.
*   Automatic IP blacklisting.
*   Works on HTTP and Socket connections.

The Firewall module is handled automatically by the App module. If you want to disable it,
set the `Settings.Firewall.enabled` settings to false.

### Imaging
*   Wrapper for ImageMagick.
*   Easy conversion between multiple image types.

The Imaging module depends on ImageMagick so please make sure you have it installed on your server
before using this module.

### Logger
*   Simple info, warn and error logging methods.
*   Suppports logging to local files, Logentries (http://logentries.com) and Loggly (http://loggly.com).

**Before you start** make sure you have enabled and set your desired transports on `Settings.Logger`.
By default no transports are enabled, so the Logger will log to the console only

To enable logging to local files, set `Settings.Logger.Local.enabled` to true and make sure to have write
access to the path set on the `Settings.Path.logsDir`.

To enable a remote logging service, simply set its token and access keys on `Settings.Logger` settings
and set `enabled` to true. At the moment the Logger supports Logentries and Loggly.

### Mail
*   Supports sending emails via SMTP using optional authentication and SSL/TLS.
*   Supports email templates and keywords.
*   Automatic switching to a failover SMTP server in case the main one fails to send.

**Before you start** make sure you have set the main SMTP server details on `Settings.Mail.smtp`. An optional
secondary can be also set on `Settings.Mail.smtp2`, and will be used only in case the main server fails.

The email templates folder is set on `Settings.Path.emailTemplatesDir`. The template handler expects a base
template called "base.html", with a keyword "{contents}" where the email contents should go.

If the `Settings.App.paas` setting is enabled, the Mail module will automatically figure out the SMTP details for
the following email services: SendGrid, Mandrill, Mailgun.

### Sockets
*   Wrapper for the Socket.IO module

The Sockets module is handled automatically by the App module. If you want to disable it,
set the `Settings.Sockets.enabled` settings to false.

### Twitter
*   Supports updating status and reading direct messages from Twitter.

**Before you start** make sure you have set the access tokens and secrets on `Settings.Twitter`. These values
will be validated when `init` is called.

### Utils
*   General utilities and helper methods.

The Utils module provides a few methods to handle settings and get information about the server and clients.

## Running on PaaS

Deploying your Expresser based app to AppFog, Heroku, OpenShift and possibly any other PaaS is dead simple.
No need to configure anything - just leave the "paas" setting on, and it will automatically get settings
from environment variables. Right now the following add-ons will be automatically identified:

*   Database: AppFog, MongoLab, MongoHQ
*   Logging: Loggly, Logentries
*   Mail: SendGrid, Mandrill, Mailgun

## Common questions and answers

#### How to use New Relic on Expresser?

The App will first try to use the `NEW_RELIC_APP_NAME` and `NEW_RELIC_LICENSE_KEY` environment variables.
If not found, it will use the values defined on `Settings.NewRelic` settings. If you don'w want to use
New Relic just leave `appName` and `licenseKey` settings empty.

Please note that New Relic will NOT be enabled under localhost and .local hostnames.

