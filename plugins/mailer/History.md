# Changelog for expresser-mailer

3.0.6
=====
* Now possible to load base template only by passing template: true on send.
* Updated nodemailer.

3.0.5
=====
* General improvements and updated documentation.

3.0.4
=====
* Updated nodemailer.

3.0.3
=====
* Updated nodemailer.

3.0.2
=====
* Updated nodemailer.

3.0.1
=====
* The doNotSend can now be set directly on send options.

3.0.0
=====
* NEW! Now using async methods.
* DEPRECATED! No more secondary SMTP options (smtp2).
* BREAKING! path for email templates is now /assets/email.
* Improved templates loading in case the base.html is not present.
* Compatible with Expresser 3.0.0.

1.2.1
=====
* Maintenance release.

1.2.0
=====
* BREAKING! Template related code was moved to the sub-class "Templates".
* BREAKING! Template related settings now under the "templates" sub-setting.
* Updated Nodemailer to 4.0.x and other dependencies.

1.1.1
=====
* History starts here :-)
