# Expresser: Logentries

Logentries plugin for Expresser. Attaches itself to the main Logger module.

### Using Logentries

Create an account on Logentries. Then register your host, and create a default log for this host. You should then get the "Token" for this log, and change the Logentries token key:

    "logger": {
        "logentries": {
            "enabled": true,
            "token": "your-logentries-token-here"
        }
    }


        }
    }

This module is a wrapper to the le_node module.
Please check https://www.npmjs.com/package/le_node for more details.