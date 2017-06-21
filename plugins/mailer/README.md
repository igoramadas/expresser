# Expresser Mailer

*Before you start* make sure you have set the main SMTP server details on `settings.mailer.smtp` and `settings.mailer.from` with a default "from" email address. An optional secondary can be also set on `settings.mailer.smtp2`, and will be used only in case the main server fails.

The template handler expects a base template called "base.html", with a keyword "{contents}" where the email contents should go.

If `settings.app.cloud` is true, the Mailer module will automatically figure out the SMTP details for the following email services: Mailgun, Mandrill, SendGrid.

### Sample code

The example below shows how to load the "login.html" template, parse and update the keywords {user} and {registrationDate} with igor and with the current date, and send a login confirmation email. The "from" address will be the default "from" address set on the settings.

    var expresser = require("expresser");
    var template = expresser.mailer.getTemplate("login");
    var keywords = {username: "igor", registrationDate: new Date()}
    var loginMessage = expresser.mailer.parseTemplate(template, keywords);

    // getting the template manually to set the email body:
    expresser.mailer.send({body: loginMessage, subject: "Login confirmation", to: "mailto@igor.com"});

    // alternate method to use templates directly via options:
    expresser.mailer.send({keywords: keywords, template: "login", subject: "Login confirmation", to: "mailto@igor.com"});

Please note that you can also use a different SMTP transport server if needed, by creating your own SMTP transport object using the "createSmtp" helper. It accepts the same options as the ones set under settings.mailer.smtp. Example below:

    var customSmtp = expresser.mailer.createSmtp({
        host: "my.smtp.com",
        port: "587"
    })

    expresser.mailer.send({subject: "Login confirmation", to: "mailto@igor.com", smtp: customSmtp});

The Mailer module is a wrapper around Nodemailer, so some of its features can be used directly. The default SMTP transport objects are exposed as "smtp" and "smtp2". More info at [url:http://www.nodemailer.com].

For detailed info on specific features, check the annotated source on /docs folder.
