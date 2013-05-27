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

### App
*   Ready to run on most PaaS providers.
*   Built-in support for New Relic (http://newrelic.com)

The App is the main module of Expresser. It creates a new Express server and set all default options like
session and cookie secrets, paths to static resources, assets bindings etc.

By Default the App will use Jade as the default template parser. The jade files should be inside the `/views/`
folder on the root of your app.  It will also use Connect Assets and serve all static files from `/public/`.
To change these paths, please edit the `Settings.Path` keys and values.

The Express server is exposed via the `App.server` property.

To enable New Relic on the server, set the `Settings.NewRelic.appName` and `settings.NewRelic.licenseKey` values
or the `NEW_RELIC_APP_NAME` and `NEW_RELIC_LICENSE_KEY` environment variables. Detailed info can be found
inside the App module source code itself.

### Database
*   Supports reading, updating and deleting documents on MongoDB servers.
*   Automatic switching to a failover database in case the main one is down.

Expresser provides a super simple failover mechanism that will switch to a backup database in case the main
database fails repeatedly. This will be activated only if you set the `Settings.Database.connString2` value.
Please note that Expresser won't keep the main and backup database in sync! If you wish to keep them in sync
you'll have to implement this feature yourself - we suggest using background workers at http://iron.io.

### Firewall
*   Automatic protection against SQLi, CSS and LFI attacks.
*   Automatic IP blacklisting.
*   Works on HTTP and Socket connections.

The Firewall module is handled automatically by the App module. If you want to disable it,
set the `Settings.Firewall.enabled` settings to false.

### Imaging
*   Wrapper for imagemagick.
*   Easy conversion between multiple image types.

The Imaging module depends on ImageMagick so please make sure you have it installed on your server
before using this module.

### Logger
*   Simple info, warn and error logging methods.
*   Suppports logging to local files, Logentries (http://logentries.com) and Loggly (http://loggly.com).

By default no transports are enabled, so the Logger will log to the console only. To enable logging to local files,
set `Settings.Logger.Local.enabled` to true and make sure to have write access to the path set on
the `Settings.Path.logsDir`.

To enable a remote logging service, simply set its token and access keys on `Settings.Logger` settings
and set `enabled` to true.

### Mail
*   Supports sending emails via SMTP using optional authentication and SSL/TLS.
*   Automatic switching to a failover SMTP server in case the main one fails to send.

### Sockets
*   Wrapper for the Socket.IO module

The Sockets module is handled automatically by the App module. If you want to disable it,
set the `Settings.Sockets.enabled` settings to false.

### Twitter
*   Supports updating status and reading direct messages from Twitter.

### Utils
*   General utilities and helper methods.

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

