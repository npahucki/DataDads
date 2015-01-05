module.exports.notifyTeam = function(title, object, params) {
    var isDev = require("cloud/utils").isDev();
    if(!isDev) {
        var teamAddress = "team@dataparenting.com";
        if(typeof params == "object") {
            // It's a template
            return module.exports.sendTemplateEmail(title,"team@dataparenting.com",object,params);
        } else{
            return module.exports.sendEmail(title,teamAddress,object, params);
        }
    } else {
        var text =  "SKIPPED EMAIL: " + title
        if(typeof object == "object") {
            text += JSON.stringify(object)
        } else {
            text += " Template:" + object + " Params:" + JSON.stringify(params)
        }
        console.log(text);
        return Parse.Promise.as(true);
    }
};

module.exports.sendTemplateEmail = function(title, recipients, templateName, templateParams) {
    var fs = require('fs');
    var ejs = require('ejs');
    var template = fs.readFileSync("cloud/email_templates/" + templateName, "utf-8");
    var renderedText = ejs.render(template, templateParams);
    return module.exports.sendEmail(title, recipients, renderedText, "text/html");
};

module.exports.sendEmail = function(title, recipients, object, mimeType) {
        var Mailgun = require('mailgun');
        Mailgun.initialize('alerts.dataparenting.com', 'key-9w2siwoh29vvj2dufcugcpymhkwr6vc3');
        var msg =  {
                  to: Array.isArray(recipients) ? recipients.join() : recipients ,
                  from: "app@alerts.dataparenting.com",
                  subject: title
                };

    if(mimeType == "text/html") {
        msg.html = object;
    } else {
        msg.text =  typeof object === 'string' ? object : JSON.stringify(object,null,4);
    }

    //console.log("*****Sending email message:" + JSON.stringify(msg));

    return Mailgun.sendEmail(msg).fail(function(error) {
        console.error("Failed to send email. Error is " + JSON.stringify(error));
    });
};
