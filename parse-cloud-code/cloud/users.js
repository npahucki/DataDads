Parse.Cloud.beforeSave(Parse.User, function (request, response) {
    var userObject = request.object;
    // Need before save beacuse after save does indicate what the dirty fields are.
    if (userObject.get("email") && userObject.dirty("email")) {
        // Wait until assignment is done.
        userObject.set("needsTipAssignmentNow", true);
        // Send morgan an email!
        require("cloud/teamnotify").notify("A user has signed up!", userObject).then(function () {
            response.success();
        })
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
            } // Else, no babies yet, we'll do this when a baby is saved.
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

