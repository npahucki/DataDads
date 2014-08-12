module.exports.notify = function(title, object) {
    var isDev = require("cloud/utils").isDev();
    if(!isDev) {
        var Mailgun = require('mailgun');
        Mailgun.initialize('alerts.dataparenting.com', 'key-9w2siwoh29vvj2dufcugcpymhkwr6vc3');
        return Mailgun.sendEmail({
          to: "team@dataparenting.com",
          from: "app@alerts.dataparenting.com",
          subject: "[DP_ALERT]:" + title,
          text: JSON.stringify(object,null,4)
        });
    }
};
