Parse.Cloud.beforeSave(Parse.User, function (request, response) {
    var userObject = request.object;
    // Need before save beacuse after save does indicate what the dirty fields are.
    if (userObject.get("email") && userObject.dirty("email")) {
        // Wait until assignment is done.
        userObject.set("needsTipAssignmentNow", true);
        
        var userName = userObject.get('email');
        var subject = "A user has signed up: " + userName;

        var notificationObject = {};
        notificationObject.user = userObject;

        var babyQuery = new Parse.Query("Babies");
            
        babyQuery.equalTo("parentUser", userObject);
        babyQuery.first().then( function( babyObject ){
            // Check if baby exists and add it to the email body.
            // Add user email / baby name to the subject if baby exists.
            if ( babyObject){
                var name = babyObject.get("name");
                subject = subject + "/" + name;
                notificationObject.baby = babyObject;
            }
            // Send morgan an email!
            require("cloud/teamnotify").notify(subject, notificationObject).then(function () {
                response.success();
            })

        }, function(error) {
            console.warn("There was an error on the babyQuery first method");
        });
    } else {
        response.success();
    }
});

Parse.Cloud.afterSave(Parse.User, function (request) {
    var userObject = request.object;
    if (userObject.get("needsTipAssignmentNow")) {
        var babyQuery = new Parse.Query("Babies");
        babyQuery.equalTo("parentUser", userObject);
        var tips = require("cloud/tips");
        tips.processBabies(babyQuery, true).then(function () {
            if (arguments.length > 0) {
                userObject.set("needsTipAssignmentNow", false);
                userObject.save();
            } else {
             // Else, no babies yet, we'll do this when a baby is saved.
             console.warn("No tip assignments made because no babies found for user " + userObject.id);
            }

        });
    }
});

Parse.Cloud.beforeSave(Parse.Installation, function (request, response) {
    if (!request.object.id) {
        require("cloud/teamnotify").notify("Someone just installed the app!", request.object).then(function () {
            response.success();
        });
    } else {
        response.success();
    }
});

