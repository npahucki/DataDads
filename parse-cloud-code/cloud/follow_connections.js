var _= require("underscore");

Parse.Cloud.define("queryMyFollowConnections", function (request, response) {
    Parse.Cloud.useMasterKey();
    var user = request.user;
    var limit = parseInt(request.params.limit);
    var skip = parseInt(request.params.skip);
    var appVersion = request.params.appVersion;



    var query1 = new Parse.Query("FollowConnections");
    query1.equalTo("user1", user);
    var query2 = new Parse.Query("FollowConnections");
    query2.equalTo("user2", user);
    var query = Parse.Query.or(query1,query2);
    query.include(["user1","user2"]);
    query.descending("invitationSentOn");
    query.skip = skip;
    query.limit = limit;

    query.find().
        then(function (results) {
                var finalResults = _.map(results, function(connectionObject) {
                    // Not a valid connection without an inviter
                    if(!connectionObject.has("user1")) throw "Connection with id " + connectionObject.id + " has no user1";
                    var isInviter = user.id == connectionObject.get("user1").id;
                    var otherUserName;
                    var otherUserAvatar = null; // TODO
                    if(isInviter) {
                        var inviteeUser = connectionObject.get("user2");
                        if(inviteeUser) {
                            otherUserName = inviteeUser.has("fullName") ? inviteeUser.get("fullName") : connectionObject.get("inviteSentToName");
                        } else {
                            // Use the name in the invite
                            otherUserName = connectionObject.get("inviteSentToName");
                        }
                    } else {
                        var inviterUser = connectionObject.get("user1");
                        otherUserName = inviterUser.has("fullName") ? inviterUser.get("fullName") : inviterUser.get("username");
                    }
                    var connection = {
                        __type : "Object",
                        className : "Parse.Cloud.FollowConnections",
                        inviteSentOn : connectionObject.get("inviteSentOn"),
                        isInviter : isInviter  ,
                        otherPartyDisplayName : otherUserName
                    };
                    if(connectionObject.has("inviteAcceptedOn")) {
                        connection["inviteAcceptedOn"] = connectionObject.get("inviteAcceptedOn");
                    }
                    if(otherUserAvatar) {
                        connection["otherPartyAvatar"] = otherUserAvatar
                    }

                    return connection;
                });
            response.success(finalResults);
        }, function (error) {
            response.error(error);
        });
});
