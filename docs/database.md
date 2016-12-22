# Expresser: Database

#### Filename: database.coffee

The Database module is a wrapper for databases that can be added to the framework via plugins.
For example the `database-mongodb` driver for MongoDB and `database-tingodb` for TingoDB file
based databases.

## Creating your own drivers

There are official drivers for MongoDB and TingoDB on the Expresser repo. If you wish to create
your own drivers (for Postgres, MySQL etc...), use these official plugins as samples.

Drivers must implement the following methods:

### get

### insert

### update

### remove

### count

---

*For detailed info on specific features, check the annotated source on /docs/source/database.html*
