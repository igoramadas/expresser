# Expresser: Loggly

Loggly plugin for Expresser. Attaches itself to the main Logger module.

### Using Loggly

Create an account on Loggly. Then register your host, and create a default log for this host. You should then get the "Token" for this log, and change the Loggly token and subdomain keys:

    "logger": { 
        "loggly": {
            "enabled": true,
            "subdomain": "my-subdomain",
            "token": "your-loggly-token-here"
