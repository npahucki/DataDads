Parse.Cloud.beforeSave(Parse.User, function(request, response) {
    var tips = require("cloud/tips");
    var userObject = request.object;

    // Need before save beacuse after save does indicate what the dirty fields are.
    if(userObject.get("email") && userObject.dirty("email")) {
        console.log("Attempting to assign tip for user's (" + userObject.id + ") babies");
        var babyQuery = new Parse.Query("Babies");
        babyQuery.equalTo("parentUser", userObject);
        tips.processBabies(babyQuery,true).then(function() {
            // Wait until assignment is done.
            response.success();
        });
    } else {
        response.success();
    }
});
