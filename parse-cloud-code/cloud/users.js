exports.isLoggedIn = function (u) {
    return u ? u.has("email") || (u.has("authData") && u.get("authData").facebook != null) : false;
};


Parse.Cloud.beforeSave(Parse.User, function (request, response) {
    var userObject = request.object;
    if (userObject.dirty("email")) {
        var userEmail = userObject.get("email");
        if (userEmail) {
            if (userEmail != userEmail.toLowerCase()) {
                response.error("EMail address should be all lowercase for user " +
                        userObject.id ? ("user id " + userObject.id) : ("username " + userObject.get("username")));
            } else {
                if(exports.isLoggedIn(userObject)) userObject.set("needsTipAssignmentNow", true);
            }
        } else {
            response.error("Can not set the already extant email '' to null for user " +
                    userObject.id ? ("user id " + userObject.id) : ("username " + userObject.get("username")));
            return;
        }
    }

    // NOTE We can not detect logins from Facebook when the user denies the email address (for some reason, the authData
    // is always changed, even if it's exactly the same. As a result, if the signs up with facebook and the email can not
    // be set, the client will manually set the needsTipAssignmentNow flag.
    response.success();
});

Parse.Cloud.afterSave(Parse.User, function (request) {
    Parse.Cloud.useMasterKey();
    var _ = require("underscore");
    var userObject = request.object;

    if (userObject.get("needsTipAssignmentNow")) {
        var babyQuery = new Parse.Query("Babies");
        babyQuery.equalTo("parentUser", userObject);

        var followConnectionsQuery = new Parse.Query("FollowConnections");
        followConnectionsQuery.equalTo("inviteSentToEmail", userObject.get("email"));
        followConnectionsQuery.include("user1");

        var babies = null;
        var followConnections = null;

        // TODO: would be better to move to a recurring process, in case this fails, it can be tried again.
        Parse.Promise.when(babyQuery.find(), followConnectionsQuery.find()).then(function (babiesResult, followConnectionsResult) {
            babies = babiesResult;
            followConnections = followConnectionsResult;
        }).then(function () {
                    // For all the follow connections we found, we need to set the user2 to this user.
                    var savePromises = [];
                    _.each(followConnections, function (followConnection) {
                        followConnection.set("user2", userObject);
                        savePromises.push(followConnection.save());
                        if (!userObject.has("fullName") && followConnection.has("inviteSentToName")) {
                            userObject.set("fullName", followConnection.get("inviteSentToName"));
                            savePromises.push(userObject.save());
                        }
                        _.each(babies, function (baby) {
                            baby.addUnique("followerEmails", followConnection.get("user1").get("email"));
                            savePromises.push(baby.save());
                        });
                    });
                    return Parse.Promise.when(savePromises);
                }).then(function () {
                    var tips = require("cloud/tips");
                    return tips.processBabies(babyQuery, true).then(function () {
                        if (arguments.length == 0) {
                            // Else, no babies yet, we'll do this when a baby is saved.
                            console.warn("No tip assignments made because no babies found for user " + userObject.id);
                        }
                    });
                }).then(function () {
                    // This is not critical, so we don't track if it failed or not.
                    var notifier = require("cloud/emails");
                    var userName = userObject.get('email');
                    var subject = "A user has signed up: " + userName;
                    var notificationObject = { user:userObject};
                    if (babies.length > 0) {
                        notificationObject.baby = babies[0];
                        subject = subject + " with baby '" + notificationObject.baby.get("name") + "'";
                    }
                    // Send morgan an email!
                    notifier.notifyTeam(subject, notificationObject);
                }).then(function () {
                    // finally clear the flag when everything worked ok.
                    userObject.set("needsTipAssignmentNow", false);
                    return userObject.save();
                }).then(function () {
                    console.log("Completed post signup processing for user " + userObject.id);
                }, function (error) {
                    console.error("Failed to complete post-signup processing for user " + userObject.id + " with error:" + JSON.stringify(error));
                });
    }

});


Parse.Cloud.afterSave(Parse.Installation, function (request) {
    if (!request.object.existed()) {
        require("cloud/emails").notifyTeam("Someone just installed the app!", request.object);
    }
});

