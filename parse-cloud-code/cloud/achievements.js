var thumbnails = require("cloud/thumbnails.js");
var search = require("cloud/search.js");


Parse.Cloud.beforeSave("MilestoneAchievements", function (request, response) {
    var achievement = request.object;

    // Make sure the id is set so that queries against the id can work
    if (achievement.get("standardMilestone") && !achievement.get("standardMilestoneId")) {
        achievement.set("standardMilestoneId",achievement.get("standardMilestone").id);
    }

    // Create the search normalized text.
    // TODO: I'm not sure this is the best way to handle this, as it duplicates and denormalizes the data.
//    var normalized = search.normalize(achievement.get("standardMilestone").get("title"), achievement.get("customTitle"));
//    achievement.set("normalizedSearchText",normalized);

    // Make the thumbnail is needed.
    var isImage = achievement.get("attachmentType") && achievement.get("attachmentType").indexOf("image/") == 0;
    var needThumbnail = achievement.dirty("attachment");
    if (!isImage || !needThumbnail) {
        response.success();
        return;
    }

    thumbnails.makeImageThumbnail(achievement.get("attachment"), 108, 108)
            .then(function (thumbnail) {
                achievement.set("attachmentThumbnail", thumbnail);
            }).then(function (result) {
                response.success();
            }, function (error) {
                response.error(error);
            });
});
