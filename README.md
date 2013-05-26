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

By Default the App will use Jade as the default template parser. The jade files should be inside the `/views/`
folder on the root of your app.  It will also use Connect Assets and serve all static files from `/public/`.
To change these paths, please edit the `Settings.Path` keys and values.

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

### Logger
*   Suppports logging to Logentries (http://logentries.com) and Loggly (http://loggly.com).

To enable a logging service, simply set its settings on `Settings.Logger`. If you don't set any settings
for Logentries and Loggly, the Logger module will log to the console only.

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
New Relic just set the appName and licenseKey to an empty string.