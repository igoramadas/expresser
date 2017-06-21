# Changelog for expresser

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
