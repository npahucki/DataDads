Parse.Cloud.beforeSave(Parse.User, function (request, response) {
    var userObject = request.object;
    // Need before save beacuse after save does indicate what the dirty fields are.
    if (userObject.dirty("email")) {
        if(userObject.get("email")) {
            // Wait until assignment is done.
            userObject.set("needsTipAssignmentNow", true);
        } else {
            response.error("Can not set the already extant email '' to null for " +
                    userObject.id ? ("user id " + userObject.id) : ("username " + userObject.get("username")));
            return;
        }
    }
    response.success();
});

Parse.Cloud.afterSave(Parse.User, function (request) {
    var userObject = request.object;
    if (userObject.get("needsTipAssignmentNow")) {
        userObject.set("needsTipAssignmentNow", false);
        userObject.save();

        var babyQuery = new Parse.Query("Babies");
        babyQuery.equalTo("parentUser", userObject);
        var tips = require("cloud/tips");
        tips.processBabies(babyQuery, true).then(function () {
            if (arguments.length == 0) {
             // Else, no babies yet, we'll do this when a baby is saved.
             console.warn("No tip assignments made because no babies found for user " + userObject.id);
            }
        });

        var notifier = require("cloud/emails");
        var userName = userObject.get('email');
        var subject = "A user has signed up: " + userName;
        var notificationObject = { user : userObject};
        babyQuery.first().then( function( babyObject ){
            // Check if baby exists and add it to the email body.
            // Add user email / baby name to the subject if baby exists.
            if (babyObject){
                var name = babyObject.get("name");
                subject = subject + " with baby '" + name + "'";
                notificationObject.baby = babyObject;
            }
            // Send morgan an email!
            notifier.notifyTeam(subject, notificationObject);
        }, function(error) {
            console.warn("There was an error looking up the baby in afterSave: " + JSON.stringify(error));
            notifier.notify(subject, notificationObject);
        });
    }
});

Parse.Cloud.afterSave(Parse.Installation, function (request) {
    if (!request.object.existed()) {
        require("cloud/emails").notifyTeam("Someone just installed the app!", request.object);
    }
});

