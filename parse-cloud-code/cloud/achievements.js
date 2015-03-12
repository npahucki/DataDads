Parse.Cloud.define("queryMyAchievements", function (request, response) {
    var thumbnails = require("cloud/thumbnails.js");
    var search = require("cloud/search.js");

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
        filterTokens = search.canonicalize(filterTokens);
        var customTitleQuery = new Parse.Query("MilestoneAchievements");
        customTitleQuery.containsAll("searchIndex", filterTokens);
        var standardMilestoneTitleQuery = new Parse.Query("MilestoneAchievements");
        var matchingStandardMilestones = new Parse.Query("StandardMilestones");
        matchingStandardMilestones.limit(1000); // TODO: this may be problematic once we have more than 1000 std milestones.
        matchingStandardMilestones.containsAll("searchIndex", filterTokens);
        standardMilestoneTitleQuery.matchesKeyInQuery("standardMilestoneId", "objectId", matchingStandardMilestones);
        // Special case where this achievement is linked to a standardMilestone but also has a customTitle, in which case we don't want to match.
        standardMilestoneTitleQuery.doesNotExist("customTitle"); // TODO: might be faster to do post filtering?
        query = Parse.Query.or(customTitleQuery, standardMilestoneTitleQuery);
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
    query.select(["attachmentThumbnail", "standardMilestone", "baby", "customTitle", "comment", "completionDate"]);
    var findPromise = query.find();

    Parse.Promise.when(countPromise, findPromise).
            then(function (count, queryResults) {
                // Now we assign the partial standardMilestones to the corresponding achievements.
                queryResults.map(function (achievement) {
                    var milestone = achievement.get("standardMilestone");
                    if (milestone) {
                        // Nasty icky hack because Parse does not let us select fields on included objects
                        ["searchIndex", "babySex", "parentSex", "shortDescription", "rangeHigh", "rangeLow"].forEach(function (attr) {
                            delete milestone.attributes[attr];
                        });
                    }
                });
                response.success({"count":count, "achievements":queryResults});
            }, function (error) {
                response.error(error);
            });

});


Parse.Cloud.beforeSave("MilestoneAchievements", function (request, response) {
    var thumbnails = require("cloud/thumbnails.js");
    var search = require("cloud/search.js");
    var achievement = request.object;

    // Make sure the id is set so that queries against the id can work
    if (achievement.get("standardMilestone") && !achievement.get("standardMilestoneId")) {
        achievement.set("standardMilestoneId", achievement.get("standardMilestone").id);
    }

    if (achievement.dirty("customTitle")) {
        var tokens = search.tokenize(achievement.get("customTitle"));
        achievement.set("searchIndex", tokens);
    }

    // Make the thumbnail is needed.
    var isImage = achievement.get("attachmentType") && achievement.get("attachmentType").indexOf("image/") == 0;
    var needThumbnail = achievement.dirty("attachment");
    var isVideo = achievement.get("attachmentType") && achievement.get("attachmentType").indexOf("video/") == 0;
    var needsVideoTranscoding = achievement.dirty("attachmentExternalStorageId");

    if (isImage && needThumbnail) {
        thumbnails.makeImageThumbnail(achievement.get("attachment"), 320, 320, true)
                .then(function (thumbnail) {
                    achievement.set("attachmentThumbnail", thumbnail);
                }).then(function (result) {
                    response.success();
                }, function (error) {
                    console.error("Could not generate thumbnail for achievement " + achievement.id + " Error: " + JSON.stringify(error));
                    response.success(); // don't fail the save!
                });
    } else if (isVideo && needsVideoTranscoding) {
        var video = require("cloud/video.js");
        var videoPath = request.user.id + "/" + achievement.get("attachmentExternalStorageId");
        video.generateWebCompatibleVideosFromMov(videoPath).
                then(function () {
                    console.log("Submit video transcoding job(s) '" + JSON.stringify(arguments) + "' for achievement " + achievement.id);
                    response.success();
                }, function (error) {
                    console.error("Could not trigger transcoding of video " + videoPath + " Error: " + JSON.stringify(error));
                    response.success(); // don't fail the save!
                });

    } else {
        response.success();
    }
});


Parse.Cloud.afterSave("MilestoneAchievements", function (request) {

    var achievement = request.object;
    var milestone = achievement.get("standardMilestone");
    var baby = achievement.get("baby");
    var isSkipped = achievement.get("isSkipped");
    var isPostponed = achievement.get("isPostponed");
    var utils = require("cloud/utils");

    var promises = [];
    if (!achievement.existed() && baby && !isSkipped && !isPostponed) {
        var daysSinceAchievement = Math.abs(utils.dayDiffFromNow(achievement.get("completionDate")));
        var connections = require("cloud/follow_connections");
        var sharingOptions = achievement.get("sharingOptions");

        if(sharingOptions ? sharingOptions.sendToFollowers : daysSinceAchievement < 7) {
            promises.push(connections.sendMonitorEmailForAchievement(achievement));
        }
    }

    if (request.user) {
        request.user.set("lastSeenAt", new Date());
        promises.push(request.user.save());
    }

    if (!achievement.existed()) {
        function incrementStat(refObjectId, type) {
            var statsQuery = new Parse.Query("Stats");
            statsQuery.equalTo("refObjectId", refObjectId);
            statsQuery.equalTo("type", type);
            return statsQuery.first().then(function (stat) {
                if (stat) {
                    stat.increment("count", 1);
                } else if (!stat) {
                    stat = new Parse.Object("Stats");
                    stat.set("type", type);
                    stat.set("refObjectId", refObjectId);
                    stat.set("count", 1);
                }
                return stat.save();
            });
        }

        // Update Baby stat
        if (baby && !(isSkipped || isPostponed)) {
            promises.push(incrementStat(baby.id, "babyNotedMilestoneCount"));
        }

        if (milestone) {
            if (isSkipped) {
                promises.push(incrementStat(milestone.id, "standardMilestoneSkippedCount"));
            } else if (isPostponed) {
                promises.push(incrementStat(milestone.id, "standardMilestonePostponedCount"));
            } else {
                promises.push(incrementStat(milestone.id, "standardMilestoneNotedCount"));
            }
        }
    }

    Parse.Promise.when(promises).then(function() {
        console.log("After save steps for achievement " + achievement.id + " successfully completed");
    },function(error) {
        console.log("Failed to execute after save steps for achievement " + achievement.id + ". Error :" + JSON.stringify(error));
    });
});

Parse.Cloud.afterDelete("MilestoneAchievements", function (request) {

    var achievement = request.object;

    var milestone = achievement.get("standardMilestone");
    var baby = achievement.get("baby");
    var isSkipped = achievement.get("isSkipped");
    var isPostponed = achievement.get("isPostponed");
    var promises = [];

    function decrementStat(refObjectId, type) {
        var statsQuery = new Parse.Query("Stats");
        statsQuery.equalTo("refObjectId", refObjectId);
        statsQuery.equalTo("type", type);
        return statsQuery.first().then(function (stat) {
            if (stat) {
                stat.increment("count", -1);
                return stat.save();
            }
        });
    }

    // Update Baby stat
    if (baby && !(isSkipped || isPostponed)) {
        promises.push(decrementStat(baby.id, "babyNotedMilestoneCount"));
    }

    if (request.user) {
        request.user.set("lastSeenAt", new Date());
        promises.push(request.user.save());
    }

    if (milestone) {
        if (isSkipped) {
            promises.push(decrementStat(milestone.id, "standardMilestoneSkippedCount"));
        } else if (isPostponed) {
            promises.push(decrementStat(milestone.id, "standardMilestonePostponedCount"));
        } else {
            promises.push(decrementStat(milestone.id, "standardMilestoneNotedCount"));
        }
    }

    Parse.Promise.when(promises).then(function() {
        console.log("After delete steps for achievement " + achievement.id + " successfully completed");
    },function(error) {
        console.log("Failed to execute after delete steps for achievement " + achievement.id + ". Error :" + JSON.stringify(error));
    });
});


Parse.Cloud.job("indexCustomTitleField", function (request, status) {
    //'use strict';
    console.log("Starting indexing of all custom title fields");

    // Set up to modify user data
    Parse.Cloud.useMasterKey();
    var promises = [];

    var achievementsQuery = new Parse.Query("MilestoneAchievements");
    achievementsQuery.exists("customTitle");
    achievementsQuery.each(function (achievement) {
        console.log("Will index:" + achievement.get("customTitle"));
        achievement.set("searchIndex", search.tokenize(achievement.get("customTitle")));
        promises.push(achievement.save());
    }).then(function () {
                console.log("Saving " + promises.length + " objects!!");
                return Parse.Promise.when(promises);
            }).then(function () {
                // Set the job's success status
                console.log("Index Done!");
                status.success("Index Done");
            }, function (error) {
                // Set the job's error status
                status.error("Failed to index : " + JSON.stringify(error));
            });
});




//NOTE THAT ACHIEVEMENT SHOULD INCLUDE THE BABY TO GET THE PARENT USER ID
function attachmentUrl(achievement) {
    if ( achievement.get("attachment") || achievement.get("attachmentExternalStorageId") ){
        var hasImage = achievement.get("attachmentType") && achievement.get("attachmentType").indexOf("image/") == 0;
        var hasVideo = achievement.get("attachmentType") && achievement.get("attachmentType").indexOf("video/") == 0;

        if (hasImage) {
            return achievement.get("attachment").url()
        } else if (hasVideo) {
            var externalId = achievement.get("attachmentExternalStorageId");
            if (externalId) {
                var s3lib = require("cloud/s3_storage.js");
                var movFilePath = achievement.get("baby").get("parentUser").id + "/" + externalId;
                return s3lib.generateSignedGetS3Url(movFilePath);
            } else {
                // Old style for backward compatible support.. no other formats available.
                return achievement.get("attachment").url();
            }
        }
    }
    else {
        return undefined;
    }
}

exports.attachmentUrl = attachmentUrl;

