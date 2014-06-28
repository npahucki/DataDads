var thumbnails = require("cloud/thumbnails.js");
var search = require("cloud/search.js");

Parse.Cloud.define("queryMyAchievements", function (request, response) {

    var babyId = request.params.babyId;
    var limit = parseInt(request.params.limit);
    var skip = parseInt(request.params.skip);
    var filterTokens = request.params.filterTokens;

    if (!babyId) {
        response.error("Invalid query, need babyId.");
        return;
    }

    var query = new Parse.Query("MilestoneAchievements");
    if (filterTokens) {
        var customTitleQuery = new Parse.Query("MilestoneAchievements");
        customTitleQuery.containsAll("searchIndex", filterTokens);
        var standardMilestoneTitleQuery = new Parse.Query("MilestoneAchievements");
        var matchingStandardMilestones = new Parse.Query("StandardMilestones");
        matchingStandardMilestones.limit(1000); // TODO: this may be problematic once we have more than 1000 std milestones.
        matchingStandardMilestones.containsAll("searchIndex", filterTokens);
        standardMilestoneTitleQuery.matchesKeyInQuery("standardMilestoneId","objectId", matchingStandardMilestones);
        // Special case where this achievement is linked to a standardMilestone but also has a customTitle, in which case we don't want to match.
        standardMilestoneTitleQuery.doesNotExist("customTitle"); // TODO: might be faster to do post filtering?
        query =  Parse.Query.or(customTitleQuery,standardMilestoneTitleQuery);
    }

    query.equalTo("baby", {__type:"Pointer", className:"Babies", objectId:babyId});
    query.equalTo("isSkipped", false);
    query.equalTo("isPostponed", false);
    query.descending("completionDate");

    // Only do the count query for the first page query.
    var countPromise = skip == 0 ? query.count() : Parse.Promise.as(-1); // do count before limits

    query.limit(limit);
    query.skip(skip);
    query.include("standardMilestone");
    query.select(["attachmentThumbnail", "standardMilestone","baby", "customTitle", "comment","completionDate"]);
    var findPromise = query.find();

    Parse.Promise.when(countPromise,findPromise).
            then(function (count, queryResults) {
                // Now we assign the partial standardMilestones to the corresponding achievements.
                queryResults.map(function(achievement) {
                    var milestone = achievement.get("standardMilestone");
                    if(milestone) {
                        // Nasty icky hack because Parse does not let us select fields on included objects
                        ["searchIndex","babySex","parentSex","shortDescription","rangeHigh","rangeLow"].forEach(function(attr) {
                            delete milestone.attributes[attr];
                         });
                    }
                });
                response.success({"count" : count, "achievements" : queryResults});
            }, function (error) {
                response.error(error);
            });

});




Parse.Cloud.beforeSave("MilestoneAchievements", function (request, response) {
    var achievement = request.object;

    // Make sure the id is set so that queries against the id can work
    if (achievement.get("standardMilestone") && !achievement.get("standardMilestoneId")) {
        achievement.set("standardMilestoneId",achievement.get("standardMilestone").id);
    }

    if(achievement.get("customTitle")) {
        var tokens = search.tokenize(achievement.get("customTitle"));
        achievement.set("searchIndex", tokens);
    }

    // Make the thumbnail is needed.
    var isImage = achievement.get("attachmentType") && achievement.get("attachmentType").indexOf("image/") == 0;
    var needThumbnail = achievement.dirty("attachment");
    if (!isImage || !needThumbnail) {
        response.success();
        return;
    }

    thumbnails.makeImageThumbnail(achievement.get("attachment"), 108, 108, true)
            .then(function (thumbnail) {
                achievement.set("attachmentThumbnail", thumbnail);
            }).then(function (result) {
                response.success();
            }, function (error) {
                response.error(error);
            });
});
