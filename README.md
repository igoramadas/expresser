# Expresser

A Node.js platform with web, database, email, logging, twitter and firewall features, built on top of Express.
Available at http://expresser.codeplex.com

### Why Expresser?

Because even if Express itself does a good job as a web application framework, it can still be considered low level.
The idea of Expresser is to aggregate common modules and utils into a single package, and make it even easier to
start your Node.js web app.

### Modules

#### App
The main module, runs an Express app inside.

#### Database
Helper to read and save data to MongoDB databases.

#### Firewall
Firewall with a few protections against HTTP and sockets attacks.

#### Logger
Helper to log to Logentries and Loggly.

#### Mail
Helper to send emails using SMTP, with templates support.

#### Sockets
Manages socket connections using Socket.IO.

#### Twitter
Helper to interact with Twitter.

### Supported PaaS

Deploying your Expresser based app to AppFog, Heroku, OpenShift and possibly any other PaaS is dead simple!
No need to configure anything - just leave the "paas" setting on, and it will automatically get settings
from environment variables. Right now the following add-ons will be automatically identified:

Database: AppFog built-in, MongoLab, MongoHQ
Email: SendGrid, Mandrill, Mailgun
Logging: Loggly, Logentries