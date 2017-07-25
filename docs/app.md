# Expresser: App

#### Filename: app.coffee

This is the core of Expresser framework. It holds the HTTP(s) server along session and cookie secrets, asset
bindings, middlewares etc. By default it will bind to all local addresses on port 8080 (when running
on your local environment). The Express server is exposed via the `server` property on the App module.

## Cookies and sessions

If you're planning to use cookies and/or sessions on your app, please update the `settings.app.cookieSecret` and
`settings.app.sessionSecret` with a strong encryption key.

## Adding extra middleware

You can bind your own middlewares to the Express server by using the `prependMiddlewares` and `appendMiddlewares`
collections. For example to use the `passport` middleware, which must be registered before the main ones:

    var expresser = require("expresser")
    var passport = require("passport")
    expresser.app.prependMiddlewares.push(passport.initialize())
    expresser.app.prependMiddlewares.push(passport.session())
    expresser.init()

And similarly, if you want to register a middleware after the main ones:

    var myCustomMiddleware = require("some-middleware")
    expresser.app.appendMiddlewares.push(myCustomMiddleware)

## Rendering / sending the response to the client

The App module has some helper methods to send the response to the browser using different formats.

#### renderView(req, res, view, options)

Renders a Pug view with options. By default Pug views are stored on /views. For example
to render the `testview.pug` containing the placeholders `pageTitle` and `pageUrl`:

    var app = expresser.app
    var options = {pageTitle: "My Page", pageUrl: "/testview/some/url"}

    app.server.get("/testview", function (req, res) {
        app.renderView(req, res, "testview.pug", options)
    })

#### renderJson(req, res, data)

Sends JSON data to the client. For example:

    var app = expresser.app
    var data = {something: "Here", code: 123, somethingElse: true}

    app.server.get("/testjson", function (req, res) {
        app.renderJson(req, res, data)
    })

#### renderError(req, res, error, status = 500)

Sends an error to the client as JSON. For example when a procedure fails (access denied or another error):

    var app = expresser.app

    app.server.get("/dosomething", function (req, res) {
        try {
            doSomething()
        } catch (ex) {
            if (ex.reason == "Not authorized") {
                app.renderError(req, res, "You have no rights to access this resource.", 403)
            } else {
                app.renderError(req, res, ex)
            }
        }
    })

#### renderImage(req, res, filename, options)

Renders an image (JPG, GIF, PNG etc...) to the client.

    var app = expresser.app

    app.server.get("/myimage", function (req, res) {
        app.renderImage(req, res, __dirname + "/myimage.jpg")
    })

---

*For detailed info on specific features, check the annotated source on /docs/source/app.html*
