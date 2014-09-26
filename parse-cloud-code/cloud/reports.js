Parse.Cloud.job("generateSummaryReport", function (request, status) {
    console.log("Starting Summary Report Generation Job...");
    Parse.Cloud.useMasterKey();
    var _ = require("underscore");
    var promises = [];
    var util = require("cloud/utils");
    var lastWeek = util.dateAddDays(new Date(), -7);

    // Number of new users in last 7 days.
    var newUserQuery = new Parse.Query(Parse.User);
    newUserQuery.greaterThan("createdAt", lastWeek);
    promises.push(newUserQuery.count());

    // Number of new milestones in last 7 days
    var newMilestoneQuery = new Parse.Query("MilestoneAchievements");
    newMilestoneQuery.greaterThan("createdAt", lastWeek);
    promises.push(newMilestoneQuery.count());

    // 20 Most active users
    var mostActiveBabiesStatQuery = new Parse.Query("Stats");
    mostActiveBabiesStatQuery.equalTo("type", "babyNotedMilestoneCount");
    mostActiveBabiesStatQuery.limit(20);
    mostActiveBabiesStatQuery.addDescending("count");
    promises.push(mostActiveBabiesStatQuery.find()
            .then(function (statsResults) {
                var counts = _.reduce(statsResults, function (map, stat) {
                    map[stat.get("refObjectId")] = stat.get("count");
                    return map;
                }, {});
                var mostActiveBabiesQuery = new Parse.Query("Babies");
                mostActiveBabiesQuery.containedIn("objectId", _.keys(counts));
                mostActiveBabiesQuery.include("parentUser");
                return mostActiveBabiesQuery.find().then(function (babies) {
                    var stats = _.map(babies, function (baby) { return { baby:baby, count:counts[baby.id]}});
                    stats = _.sortBy(stats, function (stat) { return -(stat.count) });
                    var mostActiveUserText = "<ol>";
                    _.each(stats, function (stat) {
                        // TODO: This will need adjustment when you can track two babies
                        var parent = stat.baby.get("parentUser");
                        if (parent) {
                            mostActiveUserText += "<li>" + (parent.get("email") ? parent.get("email") : parent.id) + "&lt;" + parent.get("screenName") + "&gt; (" + stat.count + ")</li>";
                        }
                    });
                    mostActiveUserText += "</ol>";
                    return Parse.Promise.as(mostActiveUserText);
                });
            })
    );


//    var statsToText = function (stats) {
//        var text = "<ol>";
//        _.each(stats, function (stat) {
//            var milestone = stat.get("standardMilestone");
//            if (milestone) { // null if deleted for some reason
//                text += "<li>" + milestone.get("title") + "(" + stat.get("count") + ")" < /li>";
//            }
//        });
//        text += "</ol>";
//        return Parse.Promise.as(text);
//    };
//
//    // 20 Most commonly logged milestones (7 days)
//    var mostActiveMilestonesThisWeekQuery = new Parse.Query("StandardMilestoneStats");
//    mostActiveMilestonesThisWeekQuery.include(["standardMilestone"]);
//    mostActiveMilestonesThisWeekQuery.limit(20);
//    mostActiveMilestonesThisWeekQuery.addDescending("count");
//    newMilestoneQuery.greaterThan("updatedAt", lastWeek);
//    promises.push(mostActiveMilestonesThisWeekQuery.find().then(statsToText));
//
//// 20 Most common milestones (all time)
//    var mostActiveMilestonesQuery = new Parse.Query("StandardMilestoneStats");
//    mostActiveMilestonesQuery.include(["standardMilestone"]);
//    mostActiveMilestonesQuery.limit(20);
//    mostActiveMilestonesQuery.addDescending("count");
//    promises.push(mostActiveMilestonesQuery.find().then(statsToText));

    Parse.Promise.when(promises).then(function (newUserCount, newMilestoneCount, mostActiveUsers, mostActiveMilestonesThisWeek, mostActiveMilestones) {

        var reportText = "<html><body><h1>Report for " + new Date() + "</h1><ul>" +
                "<li>New Users in the Last 7 days : " + newUserCount + "</li>" +
                "<li>New Milestones in the last 7 days: " + newMilestoneCount + "</li>" +
                "<li>Top 20 active users : " + mostActiveUsers + "</li>" +
                "<li>Top 20 milestones in the last 7 days : " + mostActiveMilestonesThisWeek + "</li>" +
                "<li>Top 20 milestones of all time : " + mostActiveMilestones + "</li>" +
                "</ul></body></html>";

        // Set the job's success status
        var emailer = require("cloud/teamnotify");
        emailer.notify("Daily Summary Report", reportText);
        status.success("Daily Summary Report completed successfully.");
    }, function (error) {
        // Set the job's error status
        status.error("Daily Summary Report  fatally failed : " + JSON.stringify(error));
    });
})
;

Parse.Cloud.job("generateInitialStats", function (request, status) {
    console.log("Starting Generate Initial Stats Job....");
    var _ = require("underscore");
    Parse.Cloud.useMasterKey();

    var updateOrCreateStat = function (refObjectId, type, count) {
        //console.log("Log stat for " + refObjectId + " type:" + type + " count:" + count);
        if (count <= 0) return Parse.Promise.as();
        var statsQuery = new Parse.Query("Stats");
        statsQuery.equalTo("refObjectId", refObjectId);
        statsQuery.equalTo("type", type);
        return statsQuery.first().then(function (stat) {
            if (stat && count == stat.get("count")) {
                return Parse.Promise.as();
            } else if (!stat) {
                stat = new Parse.Object("Stats");
                stat.set("type", type);
                stat.set("refObjectId", refObjectId);
            }
            stat.set("count", count);
            console.log("Saving stat " + JSON.stringify(stat));
            return stat.save();
        });
    };

    var processBaby = function (baby) {
        var achievementCountQuery = new Parse.Query("MilestoneAchievements");
        achievementCountQuery.equalTo("isPostponed", false);
        achievementCountQuery.equalTo("isSkipped", false);
        achievementCountQuery.equalTo("baby", baby);
        return achievementCountQuery.count().then(function (count) {
            return updateOrCreateStat(baby.id, "babyNotedMilestoneCount", count);
        });
    };

    var processMilestone = function (milestone) {
        // Can't do counts because of limits on counts :-( - Bad Parse!
        var achievementCountQuery = new Parse.Query("MilestoneAchievements");
        achievementCountQuery.equalTo("standardMilestone", milestone);
        achievementCountQuery.select(["isSkipped", "isPostponed"]);
        achievementCountQuery.limit(1000); // TODO: Problem when there are over 1000 noted instances!
        return achievementCountQuery.find().then(function (results) {
            var notedCount = 0;
            var skippedCount = 0;
            var postponedCount = 0;
            if (results.length) {
                _.each(results, function (achievement) {
                    if (achievement.get("isSkipped")) {
                        skippedCount++;
                    } else if (achievement.get("isPostponed")) {
                        postponedCount++;
                    } else {
                        notedCount++;
                    }
                });
                return Parse.Promise.when(
                        updateOrCreateStat(milestone.id, "standardMilestoneNotedCount", notedCount),
                        updateOrCreateStat(milestone.id, "standardMilestoneSkippedCount", skippedCount),
                        updateOrCreateStat(milestone.id, "standardMilestonePostponedCount", postponedCount)
                );
            } else {
                //console.log("No achievements for " + milestone.id);
                return Parse.Promise.as();
            }
        });
    };

    Parse.Promise.as().then(function () {
        var allBabiesQuery = new Parse.Query("Babies");
        return allBabiesQuery.each(processBaby);
    }).then(function () {
                var allStandardMilestoneQuery = new Parse.Query("StandardMilestones");
                return allStandardMilestoneQuery.each(processMilestone);
            }).then(function () {
                status.success("Stats calculation completed successfully.");
            }, function (error) {
                // Set the job's error status
                status.error("Stats calculation fatally failed : " + JSON.stringify(error));
            });
});

