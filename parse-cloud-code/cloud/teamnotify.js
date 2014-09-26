module.exports.notify = function(title, object, mimeType) {
    var isDev = require("cloud/utils").isDev();
    if(!isDev) {
        var Mailgun = require('mailgun');
        Mailgun.initialize('alerts.dataparenting.com', 'key-9w2siwoh29vvj2dufcugcpymhkwr6vc3');
        var msg =  {
                  to: "team@dataparenting.com",
                  from: "app@alerts.dataparenting.com",
                  subject: "[DP_ALERT]:" + title
                };

        if(mimeType == "text/html") {
            msg.html = object;
        } else {
            msg.text = typeof object === 'string' ? object : JSON.stringify(object,null,4);
        }
        return Mailgun.sendEmail(msg);
    } else {
        console.log("SKIPPED EMAIL: " + title + " Object:" + JSON.stringify(object));
        return Parse.Promise.as(true);
    }
};
