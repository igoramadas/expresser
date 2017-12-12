# Changelog for expresser

3.2.0
=====
* NEW! Events emitter is now exposed to external code.
* NEW! NetworkUtils now can return IPv4 and IPv6 addresses.
* BREAKING! Settings.unwatch() now replaces Settings.watch(false).
* BREAKING! BrowserUtils.getDeviceString upgraded to getDeviceDetails.
* BREAKING! SystemUtils.getIP deprecated in favour of the new getIP/getSingleIPv4 helpers on NetworkUtils.
* RENAMED! App.server is now App.expressApp.
* RENAMED! App.getRoutes is now App.listRoutes.
* DEPRECATED! Funny enough, Logger's "deprecated" helper is deprecated in favour of the built-in util.deprecate.
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
