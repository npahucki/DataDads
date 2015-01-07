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

    var finalResults = [];

    query.find().
        then(function (results) {
                var promises = _.map(results, function(connectionObject) {
                    // Not a valid connection without an inviter
                    if(!connectionObject.has("user1")) throw "Connection with id " + connectionObject.id + " has no user1";
                    var isInviter = user.id == connectionObject.get("user1").id;
                    var otherUserName;
                    var otherUserAvatar = null; // TODO
                    var inviterUser = connectionObject.get("user1");
                    var inviteeUser = connectionObject.get("user2");
                    if(isInviter) {
                        if(inviteeUser) {
                            otherUserName = inviteeUser.has("fullName") ? inviteeUser.get("fullName") : connectionObject.get("inviteSentToName");
                        } else {
                            // Use the name in the invite
                            otherUserName = connectionObject.get("inviteSentToName");
                        }
                    } else {
                        otherUserName = inviterUser.has("fullName") ? inviterUser.get("fullName") : inviterUser.get("username");
                    }
                    var connection = {
                        __type : "Object",
                        className : "Parse.Cloud.FollowConnections",
                        objectId : connectionObject.id,
                        inviteSentOn : connectionObject.get("inviteSentOn"),
                        isInviter : isInviter  ,
                        otherPartyDisplayName : otherUserName
                    };
                    if(connectionObject.has("inviteAcceptedOn")) {
                        connection["inviteAcceptedOn"] = connectionObject.get("inviteAcceptedOn");
                        // Look up baby so we can get the name and icon
                        var babyQuery = new Parse.Query("Babies");
                        babyQuery.equalTo("parentUser", isInviter ? inviteeUser : inviterUser);
                        babyQuery.limit = 1;
                        return babyQuery.first().then(function(baby) {
                            if(baby) {
                                connection["otherPartyAuxDisplayName"] = baby.get("name");
                                if(baby.has("avatarImageThumbnail"))
                                    connection["otherPartyAvatar"] = baby.get("avatarImageThumbnail").url()
                            }
                            return Parse.Promise.as(connection);
                        });
                    } else {
                        if(otherUserAvatar) {
                            connection["otherPartyAvatar"] = otherUserAvatar
                        }
                        return Parse.Promise.as(connection);
                    }
                });

                Parse.Promise.when(promises).then(function() {
                    console.log("************ RESULT:" + _.values(arguments));
                    response.success(_.values(arguments));
                })
        }, function (error) {
            response.error(error);
        });
});
