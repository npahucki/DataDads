var FollowConnection = Parse.Object.extend("FollowConnections");
var utils = require("cloud/utils");

exports.show = function (req, res) {
    Parse.Cloud.useMasterKey();

    var followedEmail = req.query.followedEmail;
    var sentToEmail = req.query.sentToEmail;
    if(!followedEmail || !sentToEmail) {
        res.send(400,"Bad request");
        return;
    }

    var followedUser = null;
    var userQuery = new Parse.Query(Parse.User);
    userQuery.equalTo("email", followedEmail);
    userQuery.first().then(function(user) {
        console.log("Followed user:" + user.id);
        followedUser = user;
    }).then(function() {
        var babyQuery = new Parse.Query("Babies");
        babyQuery.equalTo("parentUser", followedUser);
        return babyQuery.each(function (baby) {
            baby.remove("followerEmails", sentToEmail);
            return baby.save();
        });
    }).then(function() {
        var query = new Parse.Query(FollowConnection);
        query.equalTo("inviteSentToEmail",sentToEmail);
        query.equalTo("user1", followedUser);
        return query.each(function(connection) {
            return connection.destroy();
        });
    }).then(function() {
        res.render('follow/unsubscribed', {});
    }, function (error) {
        console.error(JSON.stringify(error));
        res.send(500, "An error occured during unsubscribe. Please try again.");
    });
};