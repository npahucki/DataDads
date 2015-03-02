Parse.Cloud.job("generateUserReport", function (request, status) {
    console.log("Starting User Activity Report Generation Job...");
    Parse.Cloud.useMasterKey();
    var _ = require("underscore");
    var util = require("cloud/utils");
    var lastDay = util.dateAddDays(new Date(), -1);


    // All Achievements logged in the last 24 hours
    var achievementsQuery = new Parse.Query("MilestoneAchievements");
    achievementsQuery.greaterThan("createdAt", lastDay);
    achievementsQuery.include(["baby", "baby.parentUser", "standardMilestone"]);
    achievementsQuery.limit(1000);
    achievementsQuery.ascending("createdAt");
    achievementsQuery.find().then(function (results) {
        // Need to build a map based on the parent.
        var groupedAchievements = _.groupBy(results, function (achievement) {
            var baby = achievement.get("baby");
            return baby.get("parentUser").id;
        });
        var reportText = "<html><body><h1>Report for " + new Date() + "</h1>";
        _.each(groupedAchievements, function (achievements, parentId) {
            var parent = achievements[0].get("baby").get("parentUser");
            if (parent.id != parentId) throw "WTF? Achievements not grouped";
            reportText += "<h2>" + (parent.get("email") ? parent.get("email") : parent.id) + "&lt;" + parent.get("fullName") + "&gt; (" + achievements.length + ")</h2><hr/></ol>";
            _.each(achievements, function (achievement) {
                var milestone = achievement.get("standardMilestone");
                var title = milestone ? milestone.get("title") : achievement.get("customTitle");
                var activityTime = new Date(achievement.createdAt.getTime() - 7 * 60 * 60 * 1000);
                reportText += "<li>[" + activityTime.toLocaleTimeString() + " PST] ";
                if (achievement.get("isSkipped")) {
                    reportText += "SKIPPED: ";
                } else if (achievement.get("isPostponed")) {
                    reportText += "POSTPONED: ";
                }
                reportText += title + "</li>";
            });
            reportText += "</ol><hr/><br/>";
        });
        reportText += "</body></html>";

        var emails = require("cloud/emails");
        emails.notifyTeam("[DP_ALERT]: Daily User Flow", reportText, "text/html");
        status.success("Daily User Flow Report completed successfully.");
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
    var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    var util = require("cloud/utils");
    var now = new Date(); //Date.parse("2014-10-13T00:00:00.000Z"));
    var lastWeek = util.dateAddDays(now, -7);
    var lastDay = util.dateAddDays(new Date(), -1);

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
                    var stats = _.map(objects, function (object) {
                        return { object:object, count:counts[object.id]}
                    });
                    return Parse.Promise.as(_.sortBy(stats, function (stat) {
                        return -(stat.count)
                    }));
                });
    }

    function milestoneStatsToText(statsQuery) {
        var milestoneQuery = new Parse.Query("StandardMilestones");
        return coalateStats(statsQuery, milestoneQuery).then(function (stats) {
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

    function calculateRetention(installSampleDays, activeSampleDays) {
        var UserClass = Parse.User; // Change for debugging

        // Need a count of users who installed on each of the days.
        var sampleDayCountPromises = _.map(installSampleDays, function (days) {
            var startCutOffDate = util.dateAddDays(now, -days);
            var endCutOffDate = util.dateAddDays(now, -days + 1);
            var totalUserOnDateQuery = new Parse.Query(UserClass);
            totalUserOnDateQuery.greaterThan("createdAt", startCutOffDate);
            totalUserOnDateQuery.lessThanOrEqualTo("createdAt", endCutOffDate);
            return totalUserOnDateQuery.count().then(function (count) {
                return Parse.Promise.as({ days:days, activeUserCount:{}, totalUserCount:count });
            });
        });

        return Parse.Promise.when(sampleDayCountPromises).then(function () {
                    var samples = Array.prototype.slice.call(arguments);
                    var cutOffDate = util.dateAddDays(now, -(_.max(installSampleDays)));

                    var activeUserQueryForDay = new Parse.Query(UserClass);
                    activeUserQueryForDay.greaterThanOrEqualTo("lastSeenAt", cutOffDate);
                    activeUserQueryForDay.select("lastSeenAt");
                    return activeUserQueryForDay.each(function (user) {
                        var userLastActivityDate = user.get("lastSeenAt");
                        _.each(samples, function (installSample) {
                            var installedDate = util.dateAddDays(now, -installSample.days);
                            var startInstallCutOffDate = installedDate;
                            var endInstallCutOffDate = util.dateAddDays(installedDate, 1);

                            _.each(activeSampleDays, function (activitySampleDay) {
                                var sampleEndCutOffDate = util.dateAddDays(installedDate, activitySampleDay + 1);
                                installSample.activeUserCount[activitySampleDay] |= 0;
                                if (userLastActivityDate >= sampleEndCutOffDate &&
                                        user.createdAt > startInstallCutOffDate && user.createdAt <= endInstallCutOffDate) {
                                    installSample.activeUserCount[activitySampleDay]++;
                                }
                            });
                        });
                    }).then(function () {
                                var retentionTable = [];
                                _.each(samples, function (sample) {
                                    var row = [];
                                    retentionTable.push(row);
                                    _.each(sample.activeUserCount, function (activeUserCountForDay, daysAfterInstall) {
                                        if (daysAfterInstall <= sample.days) {
                                            var percent = (sample.totalUserCount ? (activeUserCountForDay / sample.totalUserCount * 100) : 0).toFixed(2);
                                            row.push({
                                                installs:sample.totalUserCount,
                                                active:activeUserCountForDay,
                                                percent:percent
                                            });
                                        }
                                    });
                                });
                                return Parse.Promise.as(retentionTable);
                            })
                }
        );
    }
    function countUniques(query, uniqueField){
        query.select(uniqueField);
        return query.find().then(function(results){
            var arr = _.map(results, function(obj){
                if( typeof(obj.get(uniqueField)) === "object" ){
                    return obj.get(uniqueField).id;
                }
                else{
                    return obj.get(uniqueField);
                }
            });
            return Parse.Promise.as(_.uniq(arr).length);
        });
    }


    // Number of new users in last day.
    var newUsersLastDayQuery = new Parse.Query(Parse.User);
    newUsersLastDayQuery.greaterThan("createdAt", lastDay);
    promises.push(newUsersLastDayQuery.count());

    // Number of new babies in last day.
    var newBabiesLastDayQuery = new Parse.Query("Babies");
    newBabiesLastDayQuery.greaterThan("createdAt", lastDay);
    promises.push(newBabiesLastDayQuery.count());

    // Number of new installs in last day.
    var newInstallsLastDayQuery = new Parse.Query(Parse.Installation);
    newInstallsLastDayQuery.greaterThan("createdAt", lastDay);
    promises.push(newInstallsLastDayQuery.count());

    // Number of new milestones in last day
    var newMilestoneLastDayQuery = new Parse.Query("MilestoneAchievements");
    newMilestoneLastDayQuery.greaterThan("createdAt", lastDay);
    newMilestoneLastDayQuery.equalTo("isSkipped", false);
    newMilestoneLastDayQuery.equalTo("isPostponed", false);
    promises.push(newMilestoneLastDayQuery.count());

    // Number of new users in last 7 days.
    var newUsersLastWeekQuery = new Parse.Query(Parse.User);
    newUsersLastWeekQuery.greaterThan("createdAt", lastWeek);
    promises.push(newUsersLastWeekQuery.count());

    // Number of new babies in last 7 days.
    var newBabiesLastWeekQuery = new Parse.Query("Babies");
    newBabiesLastWeekQuery.greaterThan("createdAt", lastWeek);
    promises.push(newBabiesLastWeekQuery.count());

    // Number of new installs in last 7 days.
    var newInstallsLastWeekQuery = new Parse.Query(Parse.Installation);
    newInstallsLastWeekQuery.greaterThan("createdAt", lastWeek);
    promises.push(newInstallsLastWeekQuery.count());

    var anonUserQuery = new Parse.Query(Parse.User);
    anonUserQuery.doesNotExist("email");
    promises.push(anonUserQuery.count());

    var signedInUserQuery = new Parse.Query(Parse.User);
    signedInUserQuery.exists("email");
    promises.push(signedInUserQuery.count());

    // Number of new milestones in last 7 days
    var newMilestoneLastWeekQuery = new Parse.Query("MilestoneAchievements");
    newMilestoneLastWeekQuery.greaterThan("createdAt", lastWeek);
    newMilestoneLastWeekQuery.equalTo("isSkipped", false);
    newMilestoneLastWeekQuery.equalTo("isPostponed", false);
    promises.push(newMilestoneLastWeekQuery.count());

    // Total logged milestones
    var allMilestoneQuery = new Parse.Query("MilestoneAchievements");
    allMilestoneQuery.equalTo("isSkipped", false);
    allMilestoneQuery.equalTo("isPostponed", false);
    promises.push(allMilestoneQuery.count());

    // Retention Data
    var retentionRows = [];
    var installSampleDays = [2, 3, 4, 5, 6, 7, 8, 14, 21, 28, 45, 60];
    var activeSampleDays = [1,2,3,4,5,6,7,8,11,14,18,21,25,28,32,35,38,42,45,49,51,56,59,60];
    promises.push(calculateRetention(installSampleDays, activeSampleDays).then(function (retentionRows) {
        var retentionData = "<table border='1'>";
        // make the headers
        retentionData += "<tr><th></th>";
        _.each(activeSampleDays, function (day) {
            retentionData += "<th>" + day + "</th>";
        });
        retentionData += "</tr>";
        for (var rowIdx = retentionRows.length - 1; rowIdx >= 0; rowIdx--) {
            var rowHeader = installSampleDays[rowIdx];
            var installDate = util.dateAddDays(now, -rowHeader);
            var installDisplayDate = rowHeader <= 7 ? months[installDate.getMonth()] + " " + installDate.getDate() : rowHeader + " days ago";
            retentionData += "<tr><th>" + installDisplayDate + "</th>";
            var row = retentionRows[rowIdx];
            _.each(row, function (colData, colIdx) {
                var sampleDay = activeSampleDays[colIdx];
                var mouseOverText = "Of " + colData.installs + " install(s) from " + installDisplayDate + ", " + colData.active + " were active after " + sampleDay + " day(s)";
                retentionData += "<td><span title='" + mouseOverText +"'>" + (colData.installs ? colData.percent + "%" : "-") + "</span></td>";
            });
            retentionData += "</tr>";
        }
        retentionData += "</table>";
        return Parse.Promise.as(retentionData);
    }));


    // 20 Most active users
    var mostActiveBabiesStatQuery = new Parse.Query("Stats");
    mostActiveBabiesStatQuery.equalTo("type", "babyNotedMilestoneCount");
    mostActiveBabiesStatQuery.limit(20);
    mostActiveBabiesStatQuery.addDescending("count");
    mostActiveBabiesStatQuery.greaterThan("updatedAt", lastWeek);
    var babyQuery = new Parse.Query("Babies");
    babyQuery.include("parentUser");
    promises.push(coalateStats(mostActiveBabiesStatQuery, babyQuery).then(function (stats) {
        var mostActiveUserText = "<ol>";
        _.each(stats, function (stat) {
            // TODO: This will need adjustment when you can track two babies
            var baby = stat.object;
            var parent = baby.get("parentUser");
            if (parent) {
                mostActiveUserText += "<li>" + (parent.get("email") ? parent.get("email") : parent.id) + "&lt;" + parent.get("fullName") + "&gt; (" + stat.count + ")</li>";
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

    // Transactions

    // Promises order: lastWeekTransactions, lastWeekFailedTransactions, lastDayTransactions, lastDayFailedTransactions
    var lastWeekTransactionsQuery = new Parse.Query("PurchaseTransactions");
    lastWeekTransactionsQuery.greaterThan("createdAt", lastWeek);
    promises.push(lastWeekTransactionsQuery.count());
    lastWeekTransactionsQuery.equalTo("type", "failed_purchase");
    promises.push(lastWeekTransactionsQuery.count());

    var lastDayTransactionsQuery = new Parse.Query("PurchaseTransactions");
    lastDayTransactionsQuery.greaterThan("createdAt", lastDay);
    promises.push(lastDayTransactionsQuery.count());
    lastDayTransactionsQuery.equalTo("type", "failed_purchase");
    promises.push(lastDayTransactionsQuery.count());

    // FollowConnections
    //Promises order:lastWeekNewConnections, uniqueLastWeekConnections, lastDayNewConnections, uniqueLastDayNewConnections
    var lastWeekNewConnectionsQuery = new Parse.Query("FollowConnections");
    lastWeekNewConnectionsQuery.greaterThan('createdAt', lastWeek);
    promises.push(lastWeekNewConnectionsQuery.count());
    promises.push(countUniques(lastWeekNewConnectionsQuery, "user1"));

    var lastDayNewConnectionsQuery = new Parse.Query("FollowConnections");
    lastDayNewConnectionsQuery.greaterThan('createdAt', lastDay);
    promises.push(lastDayNewConnectionsQuery.count());
    promises.push(countUniques(lastDayNewConnectionsQuery, "user1"));

    Parse.Promise.when(promises).then(function ( newUserCountLastDay, newBabiesCountLastDay, newInstallCountLastDay, newMilestoneCountLastDay, newUserCountLastWeek, newBabiesCountLastWeek, newInstallCountLastWeek, anonUserCount, signedInUserCount, newMilestoneCountLastWeek, allMilestoneCount, retentionStats, mostActiveUsers, mostActiveMilestonesThisWeek, mostActiveMilestones, mostSkippedMilestones, mostPostponedMilestones, lastWeekTransactions, lastWeekFailedTransactions, lastDayTransactions, lastDayFailedTransactions, lastWeekNewConnections, uniqueLastWeekConnections, lastDayNewConnections, uniqueLastDayNewConnections) {
        var templateParams = {newUserCountLastDay: newUserCountLastDay, newBabiesCountLastDay: newBabiesCountLastDay, newInstallCountLastDay: newInstallCountLastDay , newMilestoneCountLastDay: newMilestoneCountLastDay, newUserCountLastWeek: newUserCountLastWeek, newBabiesCountLastWeek: newBabiesCountLastWeek, newInstallCountLastWeek: newInstallCountLastWeek, anonUserCount: anonUserCount, signedInUserCount: signedInUserCount, newMilestoneCountLastWeek: newMilestoneCountLastWeek, allMilestoneCount: allMilestoneCount, retentionStats: retentionStats, mostActiveUsers: mostActiveUsers, mostActiveMilestonesThisWeek: mostActiveMilestonesThisWeek, mostActiveMilestones: mostActiveMilestones, mostSkippedMilestones: mostSkippedMilestones, mostPostponedMilestones: mostPostponedMilestones, lastWeekTransactions: lastWeekTransactions, lastWeekFailedTransactions: lastWeekFailedTransactions, lastDayTransactions: lastDayTransactions, lastDayFailedTransactions: lastDayFailedTransactions, lastWeekNewConnections: lastWeekNewConnections, uniqueLastWeekNewConnections: uniqueLastWeekConnections, lastDayNewConnections: lastDayNewConnections, uniqueLastDayNewConnections: uniqueLastDayNewConnections}
        var emails = require("cloud/emails");
        emails.notifyTeam("[DP_ALERT]: Daily Summary Stats", "reports/summaryReport.ejs", templateParams);
        status.success("Daily Summary Stats Report completed successfully.");
    }, function (error) {
        // Set the job's error status
        status.error("Daily Summary Report  fatally failed : " + JSON.stringify(error));
    });
});


Parse.Cloud.job("generateInitialLastSeenDate", function (request, status) {
    console.log("Starting Generate Initial Stats Job....");
    var _ = require("underscore");
    Parse.Cloud.useMasterKey();

    new Parse.Query(Parse.User).each(function (user) {
        // Find all babies
        var usersToSave = [];
        var babyQuery = new Parse.Query("Babies");
        babyQuery.equalTo("parentUser", user);
        babyQuery.find().then(function (babies) {
            var lastAchievementQuery = new Parse.Query("MilestoneAchievements");
            lastAchievementQuery.containedIn("baby", babies);
            lastAchievementQuery.descending("createdAt");
            lastAchievementQuery.limit(1);
            return lastAchievementQuery.first();
        }).then(function (lastAchievement) {
                    if (lastAchievement) {
                        user.set("lastSeenAt", lastAchievement.createdAt);
                        console.log("Queuing user " + user.id);
                        usersToSave.push(user);
                    }
                }).then(function () {
                    return Parse.Object.saveAll(usersToSave);
                });
    }).then(function () {
                status.success("All users updated");
            }, function (error) {
                console.error(error);
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

