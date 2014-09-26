Parse.Cloud.job("generateUserReport", function (request, status) {
    console.log("Starting User Activity Report Generation Job...");
    Parse.Cloud.useMasterKey();
    var _ = require("underscore");
    var util = require("cloud/utils");
    var lastDay = util.dateAddDays(new Date(), -1);


    // All Achievements logged in the last 24 hours
    var achievementsQuery = new Parse.Query("MilestoneAchievements");
    achievementsQuery.greaterThan("createdAt", lastDay);
    achievementsQuery.include(["baby","baby.parentUser","standardMilestone"]);
    achievementsQuery.limit(1000);
    achievementsQuery.ascending("createdAt");
    achievementsQuery.find().then(function(results) {
        // Need to build a map based on the parent.
        var groupedAchievements= _.groupBy(results, function(achievement) {
                    var baby = achievement.get("baby");
                    return baby.get("parentUser").id;
                });
        var reportText = "<html><body><h1>Report for " + new Date() + "</h1>";
        _.each(groupedAchievements, function(achievements, parentId) {
            var parent = achievements[0].get("baby").get("parentUser");
            if(parent.id != parentId) throw "WTF? Achievements not grouped";
            reportText += "<h2>" + (parent.get("email") ? parent.get("email") : parent.id) + "&lt;" + parent.get("screenName") + "&gt; (" + achievements.length + ")</h2><hr/></ol>";
            _.each(achievements, function(achievement) {
                var milestone = achievement.get("standardMilestone");
                var title = milestone ? milestone.get("title") : achievement.get("customTitle");
                var activityTime = new Date(achievement.createdAt.getTime() - 7 * 60 * 60 * 1000);
                reportText += "<li>[" + activityTime.toLocaleTimeString() + " PST] " ;
                if(achievement.get("isSkipped")) {
                    reportText += "SKIPPED: ";
                } else if(achievement.get("isPostponed")) {
                    reportText += "POSTPONED: ";
                }
                reportText += title+"</li>";
            });
            reportText += "</ol><hr/><br/>";
        });
        reportText += "</body></html>";

        var emailer = require("cloud/teamnotify");
        emailer.notify("Daily DataParenting User Activity", reportText, "text/html");
        status.success("Daily User Activity Report completed successfully.");
    }, function (error) {
        // Set the job's error status
        status.error("Daily Summary Report  fatally failed : " + JSON.stringify(error));
    });
});



Parse.Cloud.job("generateSummaryReport", function (request, status) {
    console.log("Starting Summary Report Generation Job...");
    Parse.Cloud.useMasterKey();
    var _ = require("underscore");
    var promises = [];
    var util = require("cloud/utils");
    var lastWeek = util.dateAddDays(new Date(), -7);

    function coalateStats(statsQuery, objectQuery) {
        return statsQuery.find()
                .then(function (statsResults) {
                    var counts = _.reduce(statsResults, function (map, stat) {
                        map[stat.get("refObjectId")] = stat.get("count");
                        return map;
                    }, {});
                    objectQuery.containedIn("objectId", _.keys(counts));
                    return Parse.Promise.when(counts, objectQuery.find());
                }).then(function (counts, objects) {
                    var stats = _.map(objects, function (object) { return { object:object, count:counts[object.id]}});
                    return Parse.Promise.as(_.sortBy(stats, function (stat) { return -(stat.count) }));
                });
    }

    function milestoneStatsToText(statsQuery) {
        var milestoneQuery = new Parse.Query("StandardMilestones");
        return coalateStats(statsQuery, milestoneQuery).then(function(stats) {
            var text = "<ol>";
            _.each(stats, function (stat) {
                var milestone = stat.object;
                if (milestone) { // null if deleted for some reason
                    text += "<li>" + milestone.get("title") + "(" + stat.count + ")</li>";
                }
            });
            text += "</ol>";
            return Parse.Promise.as(text);
        });
    }


    // Number of new users in last 7 days.
    var newUserQuery = new Parse.Query(Parse.User);
    newUserQuery.greaterThan("createdAt", lastWeek);
    promises.push(newUserQuery.count());

    // Number of new babies in last 7 days.
    var newBabiesQuery = new Parse.Query("Babies");
    newBabiesQuery.greaterThan("createdAt", lastWeek);
    promises.push(newBabiesQuery.count());

    // Number of new installs in last 7 days.
    var newInstallQuery = new Parse.Query(Parse.Installation);
    newInstallQuery.greaterThan("createdAt", lastWeek);
    promises.push(newInstallQuery.count());

    var anonUserQuery = new Parse.Query(Parse.User);
    anonUserQuery.doesNotExist("email");
    promises.push(anonUserQuery.count());

    var signedInUserQuery = new Parse.Query(Parse.User);
    signedInUserQuery.exists("email");
    promises.push(signedInUserQuery.count());

    // Number of new milestones in last 7 days
    var newMilestoneQuery = new Parse.Query("MilestoneAchievements");
    newMilestoneQuery.greaterThan("createdAt", lastWeek);
    newMilestoneQuery.equalTo("isSkipped", false);
    newMilestoneQuery.equalTo("isPostponed", false);
    promises.push(newMilestoneQuery.count());

    // Total logged milestones
    var allMilestoneQuery = new Parse.Query("MilestoneAchievements");
    allMilestoneQuery.equalTo("isSkipped", false);
    allMilestoneQuery.equalTo("isPostponed", false);
    promises.push(allMilestoneQuery.count());


    // 20 Most active users
    var mostActiveBabiesStatQuery = new Parse.Query("Stats");
    mostActiveBabiesStatQuery.equalTo("type", "babyNotedMilestoneCount");
    mostActiveBabiesStatQuery.limit(20);
    mostActiveBabiesStatQuery.addDescending("count");
    mostActiveBabiesStatQuery.greaterThan("updatedAt", lastWeek);
    var babyQuery = new Parse.Query("Babies");
    babyQuery.include("parentUser");
    promises.push(coalateStats(mostActiveBabiesStatQuery, babyQuery).then(function(stats) {
        var mostActiveUserText = "<ol>";
        _.each(stats, function (stat) {
            // TODO: This will need adjustment when you can track two babies
            var baby = stat.object;
            var parent = baby.get("parentUser");
            if (parent) {
                mostActiveUserText += "<li>" + (parent.get("email") ? parent.get("email") : parent.id) + "&lt;" + parent.get("screenName") + "&gt; (" + stat.count + ")</li>";
            }
        });
        mostActiveUserText += "</ol>";
        return Parse.Promise.as(mostActiveUserText);
    }));

    // 20 Most commonly logged milestones (7 days)
    var mostActiveMilestonesThisWeekQuery = new Parse.Query("Stats");
    mostActiveMilestonesThisWeekQuery.equalTo("type", "standardMilestoneNotedCount");
    mostActiveMilestonesThisWeekQuery.limit(20);
    mostActiveMilestonesThisWeekQuery.addDescending("count");
    mostActiveMilestonesThisWeekQuery.greaterThan("updatedAt", lastWeek);
    promises.push(milestoneStatsToText(mostActiveMilestonesThisWeekQuery));

    // 20 Most common milestones (all time)
    var mostActiveMilestonesQuery = new Parse.Query("Stats");
    mostActiveMilestonesQuery.equalTo("type", "standardMilestoneNotedCount");
    mostActiveMilestonesQuery.limit(20);
    mostActiveMilestonesQuery.addDescending("count");
    promises.push(milestoneStatsToText(mostActiveMilestonesQuery));

    // 20 Most commonly skipped milestones (all time)
    var mostSkippedMilestonesQuery = new Parse.Query("Stats");
    mostSkippedMilestonesQuery.equalTo("type", "standardMilestoneSkippedCount");
    mostSkippedMilestonesQuery.limit(20);
    mostSkippedMilestonesQuery.addDescending("count");
    promises.push(milestoneStatsToText(mostSkippedMilestonesQuery));

    // 20 Most commonly postponed milestones (all time)
    var mostPostponedMilestonesQuery = new Parse.Query("Stats");
    mostPostponedMilestonesQuery.equalTo("type", "standardMilestonePostponedCount");
    mostPostponedMilestonesQuery.limit(20);
    mostPostponedMilestonesQuery.addDescending("count");
    promises.push(milestoneStatsToText(mostPostponedMilestonesQuery));

    Parse.Promise.when(promises).then(function (
            newUserCount,
            newBabiesCount,
            newInstallCount,
            anonUserCount,
            signedInUserCount,
            newMilestoneCount,
            allMilestoneCount,
            mostActiveUsers,
            mostActiveMilestonesThisWeek,
            mostActiveMilestones,
            mostSkippedMilestones,
            mostPostponedMilestones) {

        var reportText = "<html><body><h1>Report for " + new Date() + "</h1><ul>" +
                "<li><b>New installs in the Last 7 days :</b> " + newInstallCount + "</li>" +
                "<li><b>New users in the Last 7 days :</b> " + newUserCount + "</li>" +
                "<li><b>New babies in the Last 7 days :</b> " + newBabiesCount + "</li>" +
                "<li><b>New milestones in the last 7 days:</b> " + newMilestoneCount + "</li>" +
                "<hr/>" +
                "<li><b>Installs resulting in new babies in the last 7 days:</b> " + ((newBabiesCount / newInstallCount) * 100).toFixed(2) + "%</li>" +
                "<hr/>" +
                "<li><b>Total anonymous users :</b> " + anonUserCount + "</li>" +
                "<li><b>Total signed in users :</b> " + signedInUserCount + "</li>" +
                "<li><b>Total users :</b> " + (anonUserCount + signedInUserCount) + "</li>" +
                "<li><b>Total number of logged milestones:</b> " + allMilestoneCount + "</li>" +
                "<hr/>" +
                "<li><b>Top 20 active users in the last 7 days :</b> " + mostActiveUsers + "</li>" +
                "<hr/>" +
                "<li><b>Top 20 milestones in the last 7 days :</b> " + mostActiveMilestonesThisWeek + "</li>" +
                "</hr>" +
                "<li><b>Top 20 milestones of all time :</b> " + mostActiveMilestones + "</li>" +
                "<hr/>" +
                "<li><b>Top 20 skipped milestones :</b> " + mostSkippedMilestones + "</li>" +
                "<hr/>" +
                "<li><b>Top 20 postponed of all time :</b> " + mostPostponedMilestones + "</li>" +
                "</ul></body></html>";

        // Set the job's success status
        var emailer = require("cloud/teamnotify");
        emailer.notify("Daily DataParenting Activity", reportText, "text/html");
        status.success("Daily Summary Report completed successfully.");
    }, function (error) {
        // Set the job's error status
        status.error("Daily Summary Report  fatally failed : " + JSON.stringify(error));
    });
});

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

