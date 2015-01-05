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
    var needsVideoTranscoding =  achievement.dirty("attachmentExternalStorageId");

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
    } else if(isVideo && needsVideoTranscoding) {
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

    // Send email to any followers
    if(baby && !isSkipped && !isPostponed) {
        // Get everything we need in one fell swoop
        var query = new Parse.Query("MilestoneAchievements");
        query.include("standardMilestone");
        query.include("baby");
        return query.get(achievement.id).then(function (achievement) {
            milestone = achievement.get("standardMilestone");
            baby = achievement.get("baby");
            var followerEmails = baby.get("followerEmails");
            if(followerEmails) {
                var milestonePromise = milestone ? milestone.fetch() : Parse.promise.as();
                return milestonePromise.then(function(populatedMilestone) {
                    milestone = populatedMilestone;
                    var subjectText = baby.get("name") + " has just completed a milestone!";
                    var title = achievement.has("customTitle") ? achievement.get("customTitle") : milestone.get("title")
                    var utils = require("cloud/utils");
                    var params = {
                        title : utils.replacePronounTokens(title, baby.get("isMale"), "en"),
                        linkUrl  : "http://dataparenting-dev.parseapp.com/achievements/" + achievement.id,
                        imageUrl : achievement.has("attachmentThumbnail") ? achievement.get("attachmentThumbnail").url() : null
                    };
                    var emails = require('cloud/emails.js');
                    return emails.sendTemplateEmail(subjectText, followerEmails,"follow/notification.ejs", params);
                });
            }
        });
    }

    if(request.user) {
        request.user.set("lastSeenAt", new Date());
        request.user.save();
    }

    if(!achievement.existed()) {
        function incrementStat(refObjectId,type) {
            var statsQuery = new Parse.Query("Stats");
            statsQuery.equalTo("refObjectId", refObjectId);
            statsQuery.equalTo("type",type);
            return statsQuery.first().then(function(stat) {
              if(stat) {
                stat.increment("count", 1);
              } else if(!stat) {
                   stat = new Parse.Object("Stats");
                   stat.set("type", type);
                   stat.set("refObjectId",refObjectId);
                   stat.set("count", 1);
               }
               return stat.save();
            });
        }

        // Update Baby stat
        if(baby && !(isSkipped || isPostponed)) {
            incrementStat(baby.id, "babyNotedMilestoneCount");
        }


        if(milestone) {
            if(isSkipped) {
                incrementStat(milestone.id,"standardMilestoneSkippedCount");
            } else if(isPostponed) {
                incrementStat(milestone.id,"standardMilestonePostponedCount");
            } else {
                incrementStat(milestone.id,"standardMilestoneNotedCount");
            }
        }
    }
});

Parse.Cloud.afterDelete("MilestoneAchievements", function (request) {

    var achievement = request.object;

    var milestone = achievement.get("standardMilestone");
    var baby = achievement.get("baby");
    var isSkipped = achievement.get("isSkipped");
    var isPostponed = achievement.get("isPostponed");

    function decrementStat(refObjectId,type) {
        var statsQuery = new Parse.Query("Stats");
        statsQuery.equalTo("refObjectId", refObjectId);
        statsQuery.equalTo("type",type);
        return statsQuery.first().then(function(stat) {
          if(stat) {
            stat.increment("count", -1);
            return stat.save();
          }
        });
    }

    // Update Baby stat
    if(baby && !(isSkipped || isPostponed)) {
        decrementStat(baby.id, "babyNotedMilestoneCount");
    }

    if(request.user) {
        request.user.set("lastSeenAt", new Date());
        request.user.save();
    }

    if(milestone) {
        if(isSkipped) {
            decrementStat(milestone.id,"standardMilestoneSkippedCount");
        } else if(isPostponed) {
            decrementStat(milestone.id,"standardMilestonePostponedCount");
        } else {
            decrementStat(milestone.id,"standardMilestoneNotedCount");
        }
    }
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
