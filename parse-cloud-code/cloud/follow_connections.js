var _ = require("underscore");

function lookupFirstBabyForUser(user) {
    var babyQuery = new Parse.Query("Babies");
    babyQuery.equalTo("parentUser", user);
    babyQuery.limit = 1;
    return babyQuery.first();
}

// Returns a promise, that succeeds if the connection object is looked up and
// the user in the request is either the inviter or invitee
function lookupConnectionObject(request) {

    var query = new Parse.Query("FollowConnections");
    query.include(["user1", "user2"]);
    var connectionObjectPromise = query.get(request.params.connectionObjectId);

    return Parse.Promise.when(request.user.fetch(), connectionObjectPromise).then(function (user, connectionObject) {
        var promise = new Parse.Promise();
        if (connectionObject) {
            var hasPermission = user.id == connectionObject.get("user1").id ||
                    (connectionObject.has("user2") ?
                            user.id == connectionObject.get("user2").id :
                            user.get("email") == connectionObject.get("inviteSentToEmail"));

            if (hasPermission) {
                promise.resolve(connectionObject, user);
            } else {
                promise.reject("Permission Denied");
            }
        } else {
            promise.reject({ code:101, message:"No Object found with id " + connectionObjectId});
        }

        return promise;
    });
}

Parse.Cloud.define("queryMyFollowConnections", function (request, response) {
    Parse.Cloud.useMasterKey();
    var user = request.user;
    var limit = parseInt(request.params.limit);
    var skip = parseInt(request.params.skip);
    var appVersion = request.params.appVersion;

    user.fetch().then(function (fullUser) {
        user = fullUser;

        var query1 = new Parse.Query("FollowConnections");
        query1.equalTo("user1", user);
        var query2 = new Parse.Query("FollowConnections");
        query2.equalTo("user2", user);
        var query3 = new Parse.Query("FollowConnections");
        query3.equalTo("inviteSentToEmail", user.get("email"));

        var query = Parse.Query.or(query1, query2, query3);
        query.include(["user1", "user2"]);
        query.descending("invitationSentOn");
        query.skip = skip;
        query.limit = limit;

        return query.find().
                then(function (results) {
                    var promises = _.map(results, function (connectionObject) {
                        // Not a valid connection without an inviter
                        if (!connectionObject.has("user1")) throw "Connection with id " + connectionObject.id + " has no user1";
                        var isInviter = user.id == connectionObject.get("user1").id;
                        var otherUserName;
                        var otherUserAvatar = null; // TODO
                        var inviterUser = connectionObject.get("user1");
                        var inviteeUser = connectionObject.get("user2");
                        if (isInviter) {
                            otherUserName =  connectionObject.has("inviteSentToName") ?
                                    connectionObject.get("inviteSentToName") :
                                    connectionObject.get("inviteSentToEmail");
                            // Always prefer what the user says his name is, if he does at all
                            if (inviteeUser && inviteeUser.has("fullName")) {
                                otherUserName =  inviteeUser.get("fullName")
                            }
                        } else {
                            otherUserName = inviterUser.has("fullName") ? inviterUser.get("fullName") : inviterUser.get("username");
                        }
                        var connection = {
                            __type:"Object",
                            className:"Parse.Cloud.FollowConnections",
                            objectId:connectionObject.id,
                            inviteSentOn:connectionObject.get("inviteSentOn"),
                            isInviter:isInviter,
                            otherPartyDisplayName:otherUserName
                        };
                        if (connectionObject.has("inviteAcceptedOn")) {
                            connection["inviteAcceptedOn"] = connectionObject.get("inviteAcceptedOn");
                            // Look up baby so we can get the name and icon
                            return lookupFirstBabyForUser(isInviter ? inviteeUser : inviterUser).then(function (baby) {
                                if (baby) {
                                    connection["otherPartyAuxDisplayName"] = baby.get("name");
                                    if (baby.has("avatarImageThumbnail"))
                                        connection["otherPartyAvatar"] = baby.get("avatarImageThumbnail").url()
                                }
                                return Parse.Promise.as(connection);
                            });
                        } else {
                            if (otherUserAvatar) {
                                connection["otherPartyAvatar"] = otherUserAvatar
                            }
                            return Parse.Promise.as(connection);
                        }
                    });

                    Parse.Promise.when(promises).then(function () {
                        response.success(_.values(arguments));
                    })
                }, function (error) {
                    response.error(error);
                });
    });
});



Parse.Cloud.define("deleteFollowConnection", function (request, response) {
    Parse.Cloud.useMasterKey();
    var connectionObject;
    lookupConnectionObject(request).then(function(newConnectionObject) {
        connectionObject = newConnectionObject;
        // Break the connection in the babies, so there are no more email updates.
        var user1 = connectionObject.get("user1");
        var user2 = connectionObject.get("user2");
        // Only if both users are present, can we attempt to undo the email links.
        // If the invitation was never accepted, then user2 will be undefined.
        if(user1 && user2) {
            var babyQuery1 = new Parse.Query("Babies");
            babyQuery1.equalTo("parentUser", user1);
            var babyPromise1 = babyQuery1.each(function(baby) {
                baby.remove("followerEmails",user2.get("email"));
                return baby.save();
            });
            var babyQuery2 = new Parse.Query("Babies");
            babyQuery2.equalTo("parentUser", user2);
            var babyPromise2 = babyQuery2.each(function(baby) {
                baby.remove("followerEmails",user1.get("email"));
                return baby.save();
            });
            return Parse.Promise.when(babyPromise1, babyPromise2);
        }
    }).then(function() {
        return connectionObject.destroy();
    }).then(function() {
        response.success(true);
    },
    function(error) {
        response.error(error);
    });
});

Parse.Cloud.define("sendFollowInvitation", function (request, response) {

    if(!request.user) {
        response.error("No User in Request");
        return;
    }

    if(!request.params.invites) {
        response.error("Missing Invitations");
        return;
    }

    var utils = require("cloud/utils");
    Parse.Cloud.useMasterKey();
    var promises = _.map(request.params.invites, function(invite) {
        if(utils.isValidEmailAddress(invite.sendToEmail)) {
            var existingConnectionQuery = new Parse.Query("FollowConnections");
            existingConnectionQuery.equalTo("user1", request.user);
            existingConnectionQuery.equalTo("inviteSentToEmail", invite.sendToEmail);
            return existingConnectionQuery.first().then(function(existingConn) {
                if(existingConn) {
                    if(existingConn.has("inviteAcceptedOn")) {
                        console.warn("Ignored request to send invite for an already accepted connection:" + existingConn.id);
                    } else {
                        existingConn.set("inviteSentOn", new Date());
                        existingConn.unset("inviteDeliveredOn");
                        return existingConn.save();
                    }
                } else {
                    var conn = new Parse.Object("FollowConnections");
                    conn.set("user1", request.user);
                    conn.set("inviteSentToEmail", invite.sendToEmail);
                    conn.set("inviteSentOn", new Date());
                    if(invite.sendToName) conn.set("inviteSentToName", invite.sendToName);
                    var lookUpUserByEmailQuery = new Parse.Query(Parse.User);
                    lookUpUserByEmailQuery.equalTo("email",invite.sendToEmail);
                    return lookUpUserByEmailQuery.first(function(invitedUser) {
                        if(invitedUser) {
                            conn.set("user2",invitedUser);
                        } // else, user not in system already
                        return conn.save();
                    });
                }
            });
        } else {
            console.warn("Skipped sending invite to invalid email address:" + invite.sendToEmail);
        }
    });

    Parse.Promise.when(promises).then(function() {
        response.success(true);
    }, function(error) {
        response.error(error);
    });
});

Parse.Cloud.define("resendFollowConnectionInvitation", function (request, response) {
    Parse.Cloud.useMasterKey();
    lookupConnectionObject(request).then(function (newConnectionObject) {
        newConnectionObject.set("inviteSentOn", new Date());
        newConnectionObject.unset("inviteDeliveredOn");
        return newConnectionObject.save();
    }).then(function () {
        response.success(true);
    },
    function (error) {
        response.error(error);
    });
});


Parse.Cloud.define("acceptFollowConnectionInvitation", function (request, response) {
    Parse.Cloud.useMasterKey();
    var connectionObject;
    var user;

    lookupConnectionObject(request).then(function (newConnectionObject, newUser) {
        connectionObject = newConnectionObject;
        user = newUser;
    }).then(function () {
        connectionObject.set("inviteAcceptedOn", new Date());
        if (!connectionObject.has("user2")) connectionObject.set("user2", user);
        return connectionObject.save();
    }).then(function () {
        // If the invited user did not have a name set, then we should set the name to what was in the invite request
        if (!user.has("fullName") && connectionObject.has("inviteSentToName")) {
            user.set("fullName", connectionObject.get("inviteSentToName"));
            return user.save();
        }
    }).then(function () {
        // Now, set the email lists for the babies of each user (mutually).
        var user1 = connectionObject.get("user1");
        var user2 = connectionObject.get("user2");

        var babyQuery1 = new Parse.Query("Babies");
        babyQuery1.equalTo("parentUser", user1);
        var babyPromise1 = babyQuery1.each(function(baby) {
            baby.addUnique("followerEmails",user2.get("email"));
            return baby.save();
        });

        var babyQuery2 = new Parse.Query("Babies");
        babyQuery2.equalTo("parentUser", user2);
        var babyPromise2 = babyQuery2.each(function(baby) {
            baby.addUnique("followerEmails",user1.get("email"));
            return baby.save();
        });

        return Parse.Promise.when(babyPromise1, babyPromise2);
    }).then(function () {
        response.success(true);
    },
    function (error) {
        response.error(error);
    });

});



