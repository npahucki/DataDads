module.exports.notifyTeam = function(title, object, params) {
    var isDev = require("cloud/utils").isDev();
    if(isDev) title = "[DEV]:" + title
    var teamAddress = "team@dataparenting.com";
    if(typeof params == "object") {
        // It's a template
        return module.exports.sendTemplateEmail(title,"team@dataparenting.com",object,params);
    } else{
        return module.exports.sendEmail(title,teamAddress,object, params);
    }
};

module.exports.sendTemplateEmail = function(title, recipients, templateName, templateParams, behalfOfUser) {
    var fs = require('fs');
    var ejs = require('ejs');
    var template = fs.readFileSync("cloud/email_templates/" + templateName, "utf-8");
    var renderedText = ejs.render(template, templateParams);
    return module.exports.sendEmail(title, recipients, renderedText, "text/html", behalfOfUser);
};

module.exports.sendEmail = function (title, recipients, object, mimeType, behalfOfUser) {
    var Mailgun = require('mailgun');
    Mailgun.initialize('alerts.dataparenting.com', 'key-9w2siwoh29vvj2dufcugcpymhkwr6vc3');

    var fromEmail = "DataParenting <robot@dataparenting.com>";
    var replyToEmail = fromEmail;
    if(behalfOfUser) {
        var userName = behalfOfUser.get("fullName");
        replyToEmail = behalfOfUser.get("email");
        if(userName) {
            replyToEmail = userName + " <" + replyToEmail + ">";
            fromEmail = userName + " <robot@dataparenting.com>";
        }
    }

    var msg = {
        to:Array.isArray(recipients) ? recipients.join() : recipients,
        from:fromEmail,
        "h:Reply-To" : replyToEmail,
        subject:title
    };

    if (mimeType == "text/html") {
        msg.html = object;
    } else {
        msg.text = typeof object === 'string' ? object : JSON.stringify(object, null, 4);
    }

    return Mailgun.sendEmail(msg).fail(function (error) {
        console.error("Failed to send email. Error is " + JSON.stringify(error));
    });
};
