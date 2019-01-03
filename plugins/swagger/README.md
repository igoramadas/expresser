# Expresser Swagger

The Swagger plugin makes it very easy to setup routes on the Express app
based on swagger specs. At the moment it supports Swagger 2.0 only.

### Sample code

The sample code below assumes you have a database object with users
and teams, and a swagger definition that makes use of the operations
`getUser()` and `getTeam()`.

    var expresser = require("expresser")
    var swagger = require("expresser-swagger")
    var users = database.users
    var teams = database.teams

    var apiRoutes = {
        getUser: function(req, res) -> return users.find(req.params),
        getTeam: function(req, res) -> return teams.find(req.params)
        // etc...
    }

    swagger.setup(apiRoutes)

### Cast parameters

By default routes handled by the Swagger module will have a "swagger" property
with the specified query, header and params. For example:

    getAddress: function(req, res) ->
       // Show route headers
       console.dir(req.swagger.header)
       // Show route query
       console.dir(req.swagger.query)
       // Show route named parameters
       console.dir(req.swagger.params)

If you do not wish to use these, you can avoid the slight processing overhead
by setting `settings.swagger.castParameters` to false.

Please note that you can change the file name and other parsing options
on the settings.
