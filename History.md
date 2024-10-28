# Changelog for Expresser

5.0.0
=====
* BREAKING! Now using Express 5.x.x, migration guide: https://expressjs.com/en/guide/migrating-5.html
* Removed http2-express-bridge.

4.8.3
=====
* Update SetMeUp and other dependencies.
* Compatible with the APP_ENV environment variable (in addition to NODE_ENV).

4.8.2
=====
* Possibility to set a path and handler on prepend / appended middlewares.
* Updated dependencies.

4.8.1
=====
* Updated dependencies.

4.8.0
=====
* Handle URI errors if the errorHandler setting is enabled.
* Updated dependencies.

4.7.1
=====
* Do not warn about the missing express-body-parser-error-handler package.
* Convert statuses to numbers before sending helper responses.

4.7.0
=====
* NEW! Support for HTTP2, can be enabled by setting app.http2 to true.
* Support for the express-body-parser-error-handler module.
* Code refactoring.
* Updated dependencies.

4.6.2
=====
* Updated dependencies.

4.6.1
=====
* New "errorHandler" setting to log all failed requests.
* Fixed regression bug on 4.6.0 (removed from NPM).
* Updated dependencies.

4.5.1
=====
* Updated dependencies.

4.5.0
=====
* Updated dependencies.
* Removed unnecessary logger cleanup methods.

4.4.7
=====
* Updated dependencies.

4.4.6
=====
* Updated dependencies.

4.4.5
=====
* New app.head() shortcut.
* Updated dependencies.

4.4.4
=====
* Updated dependencies.

4.4.3
=====
* Option to disable the raw body-parser by setting rawTypes to null.
* Updated dependencies.

4.4.1
=====
* Disable the X-Powered-By header by default.
* Updated dependencies.

4.4.0
=====
* Removed the "moment" dependency.
* Updated dependencies.

4.3.2
=====
* Updated dependencies.

4.3.1
=====
* Updated dependencies.

4.3.0
=====
* NEW! Added raw and text body parsers.
* DEPRECATED! The legacy plugin for v3 is now officially deprecated.
* Some refactoring here and there.
* Updated dependencies.

4.2.4
=====
* Updated dependencies.

4.2.3
=====
* Force status codes as number on app.renderError().
* Updated dependencies.

4.2.2
=====
* Updated dependencies.

4.2.1
=====
* New app.set() shortcut.
* Updated dependencies.

4.2.0
=====
* TypeScript types are now exported with the library.

4.1.2
=====
* Updated dependencies.

4.1.1
=====
* Defining settings.general.debug = true should also add "debug" to the Anyhow logger levels.
* Updated dependencies.

4.1.0
=====
* NEW! Routes module to load and manage routes, supports Swagger specs.
* NEW! All app render methods now accept a status code as last parameter.
* Shortcut: "app.ssl=false" == "app.ssl.enabled=false"
* General refactoring.
* Updated dependencies.

4.0.5
=====
* Fixed app.renderError(), should always return a JSON now.
* Updated dependencies.

4.0.4
=====
* Index is now a dedicated Expresser class.
* Updated dependencies.

4.0.3
=====
* Improved error responses using app.renderError().
* Fixed mutation issues when logging certain types of errors.

4.0.2
=====
* The Logger preprocessor now clones objects beforing logging.

4.0.1
=====
* Fixed the timeout behaviour on the app server.

4.0.0
=====
* A NEW EXPRESSER, BUILT FROM SCRATCH WITH TYPESCRIPT!
* Migration docs: https://github.com/igoramadas/expresser/wiki/Migration-from-v3-to-v4

========================
========================
Legacy versions below...
========================

3.5.3
=====
* FEATURE-FREEZE ON V3!!! Next Expresser v4 will be written from scratch.
* Updated dependencies.

3.5.2
=====
* Updated dependencies.

3.5.1
=====
* NEW! Added option to include / exclude labels from system.getInfo() output.
* Updated dependencies.

3.5.0
=====
* BREAKING! SystemUtils getInfo() renamed process attributes: memoryUsage to memoryUsed, memoryHeapUsage to memoryHeapUsed.
* Settings (de)encryption now using up-to-date methods - note that your current key might need to be updated.
* Improved app.renderError().
* Updated dependencies.

3.4.7
=====
* System getInfo() util has new property names on "process" information.
* Now including a package-lock.json file.

3.4.6
=====
* Maintenance release with updated dependencies.

3.4.5
=====
* Improved Logger, it now better handles moments, dates etc.

3.4.4
=====
* Logger console now respects settings.logger.sendTimestamp option.
* Updated dependencies.

3.4.3
=====
* NEW! App.renderText() to send data as plain text to the client.

3.4.2
=====
* NEW! The app server timeout can be set on settings.app.timeout.
* Updated dependencies.

3.4.1
=====
* NEW! App trustProxy option, default is 1.
* NEW! Session proxy and resave settings.
* Renamed App "compressionEnabled" setting renamed to "compression".
* Removed unecessary files from published package.

3.4.0
=====
* NEW! Session saveUninitialized setting, default is false.
* BREAKING! Session and cookie "secret" setting meged onto settings.app.secret.
* BREAKING! Session cookies now secure be default (settings.app.session.secure = true).
* Fixed issues with Session / Memory Store expiration.
* Updated dependencies.

3.3.4
=====
* Maintenance release with updated dependencies.

3.3.3
=====
* Session now gets instantiated with a proper "checkPeriod".
* Removed deprecated code.

3.3.2
=====
* NEW! Possible to disable Logger console styles by using settings.logger.styles = false.
* Updated dependencies.

3.3.1
=====
* NEW / BREAKING! Now using express-session with memory store instead of cookie based.
* NEW! Logger now emit important logging events: Logger.on.warn, Logger.on.error, Logger.on.critical
* BREAKING! Default views path moved from /views to /assets/views.
* Fixed chalk styles for deprecated Logger messages.
* Updated utils.browser.getClientIP() to better support Socket.IO.
* App.renderError will NOT log an error automatically now.
* Improved exception logging when using the Logger.
* Updated dependencies.

3.2.3
=====
* Fixed "argsCleaner" on Logger when not passing an array.

3.2.2
=====
* Added console style for deprecated messages on Logger.
* Updated dependencies.

3.2.1
=====
* NEW! Using a faster event emitter.
* Updated dependencies.

3.2.0
=====
* NEW! Events emitter is now exposed to external code.
* NEW! NetworkUtils now can return IPv4 and IPv6 addresses.
* BREAKING! Settings.unwatch() now replaces Settings.watch(false).
* BREAKING! BrowserUtils.getDeviceString upgraded to getDeviceDetails.
* BREAKING! SystemUtils.getIP deprecated in favour of the new getIP/getSingleIPv4 helpers on NetworkUtils.
* BREAKING! Calling module methods via events is not possible anymore (not worth the performance penalty).
* BREAKING! Plugins do not emit a "before.init" event any longer.
* RENAMED! App.server is now App.expressApp.
* RENAMED! App.getRoutes is now App.listRoutes.
* Massive code refactoring!

3.1.0
=====
* NEW! Logger has a new "compact" option to compact log output to single line, enabled by default.
* NEW! Logger "onLog" callback (so you can add custom post-log routines).
* NEW! App has now a "version" attribute taken directly from package.json.
* NEW! Accept invalid certificates by using "settings.app.sll.rejectUnauthorized = false".
* RENAMED! Logger "maxDeepLevel" setting renamed to "maxDepth".
* Code cleanup and some bits of refactoring.
* Updated dependencies.

3.0.7
=====
* Updated dependencies.
* Bits of code refactoring.

3.0.6
=====
* Updated dependencies.

3.0.4
=====
* NEW! Helper function "sleep" on IO utils to delay async code execution.
* Updated dependencies.

3.0.3
=====
* Updated dependencies.

3.0.2
=====
* Fixed bugs when bundling and compressing assets (mincer).
* Support for sourceMaps on bundled JS temporarily disabled.

3.0.1
=====
* NEW! Now using async / await whenever applicable. Callbacks are being phased out!
* NEW! App has now a getRoutes helper to list all registered routes.
* NEW! Logger has now a `maskFields` option in addition to the `obfuscateFields`.
* NEW! Now using CoffeeScript v2.
* DEPRECATED! Database plugins are now standalone and the old `database.coffee` wrapper is not deprecated.
* Lots of unecessary modules and code removed, plus the usual bug fixing :-)

2.4.2
=====
* Fixed default views path (/views).
* Updated styles for the Logger console.
* General fixes.

2.4.1
=====
* Fixed major bug initializing plugins introduced with 2.3.4 (unpublished).

2.4.0
=====
* BREAKING! Old settings.path.viewDir|publicDir moved to settings.app.viewPath|publicPath.
* Improved handling of errors rendering views and data on App.
* Bits of code refactoring.

2.3.3
=====
* Improved utils.data to better handle empty and invalid strings.
* Updated dependencies.

2.3.2
=====
* Updated dependencies.

2.3.1
=====
* Bug fix on utils.io.getFilePath.

2.3.0
=====
* BREAKING! Utils split into smaller classes (utils.browser, utils.data, utils.io, utiils.network, utils.system).
* BREAKING! Session and Cookie options namespaced on settings (settings.app.session.*, settings.app.cookie.*)
* Logger module is now more resilient (logging data from closed streams won't throw an exception for example).
* Default name engine renamed from jade to pug.
* Updated dependencies to their latest versions.

2.2.5
=====
* New util: maskString, to mask phone numbers and other values.
* Updated dependencies to their latest versions.

2.2.4
=====
* New app.sessionMaxAge setting to expire sessions.
* The settings.general.ioCacheTimeout is now 30 sec (was 60 sec).
* Updated dependencies to their latest versions.
* Minor refactoring.

2.2.3
=====
* Unpublished due to typo on Pug version.

2.2.2
=====
* History starts here :-)

1.0.0
=====
* First public release.
