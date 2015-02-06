var thumbnails = require("cloud/thumbnails.js");


Parse.Cloud.beforeSave("Babies", function (request, response) {

    var baby = request.object;
    if (!baby.dirty("avatarImage")) {
        // No photo provided for the baby
        response.success();
        return;
    }

    thumbnails.makeImageThumbnail(baby.get("avatarImage"), 108, 108, true)
            .then(function (thumbnail) {
                baby.set("avatarImageThumbnail", thumbnail);
            }).then(function (result) {
                response.success();
            }, function (error) {
                response.error(error);
            });
});

Parse.Cloud.afterSave("Babies", function (request) {
    var baby = request.object;
    if(!baby.existed()) { // Only for new babies, not existing saves.
        var tips = require("cloud/tips");
        return tips.processBaby(baby, false).then(function (result) {
            console.log("Automatically assigned tip for baby " + baby.id);
        }).then(function() {
            var followConnectionsQuery = new Parse.Query("FollowConnections");
            followConnectionsQuery.equalTo("user2", baby.get("parentUser"));
            followConnectionsQuery.include("user1");
            return followConnectionsQuery.find();
        }).then(function(connections) {
            var _ = require("underscore");
            _.each(connections, function(connection) {
                var inviterUser = connection.get("user1");
                baby.addUnique("followerEmails", inviterUser.get("email"));
            });
            return baby.save();
        }, function (error) {
            console.error("Failed to assigned tip for baby " + baby.id + ". Error " + JSON.stringify(error));
        });
    }
});
