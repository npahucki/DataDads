var FollowConnection = Parse.Object.extend("FollowConnections");
var utils = require("cloud/utils");

exports.show = function (req, res) {
    Parse.Cloud.useMasterKey();
    var query = new Parse.Query(FollowConnection);
    query.include(["user1","user2"]);
    query.get(req.params.id).then(function (followConnectionInvite) {
        if(followConnectionInvite) {
            var isAlreadyAccepted = followConnectionInvite.has("inviteAcceptedOn");
            var acceptPromise = Parse.Promise.as(true);
            if(!isAlreadyAccepted) {
                followConnectionInvite.set("inviteAcceptedOn", new Date());
                acceptPromise = followConnectionInvite.save();
            }
            return acceptPromise.then(function() {
                res.render('follow/invite_accepted', {
                    isExistingUser : followConnectionInvite.has("user2"),
                    isInviteAlreadyAccepted : isAlreadyAccepted
                });
            })
        } else {
            res.send(404, "Invitation is invalid");
        }
    }, function (error) {
        console.error(JSON.stringify(error));
        res.send(500, "Could not display Achievement");
    });
};