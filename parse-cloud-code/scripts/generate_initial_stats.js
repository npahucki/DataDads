var Parse = require('./init_parse').createParse();

var updateOrCreateStat = function(refObjectId,type, count) {
    if(count <= 0) return Parse.Promise.as();
    var statsQuery = new Parse.Query("Stats");
    statsQuery.equalTo("refObjectId", refObjectId);
    statsQuery.equalTo("type",type);
    return statsQuery.first().then(function(stat) {
      if(stat && count == stat.get("count")) {
         console.log("No need to log stat for " + refObjectId + ":" + type);
         return Parse.Promise.as();
      } else if(!stat) {
           stat = new Parse.Object("Stats");
           stat.set("type", type);
           stat.set("refObjectId",refObjectId);
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
        return updateOrCreateStat(baby.id,"babyNotedMilestoneCount", count);
    });
};

var processMilestone = function (milestone) {
    var achievementCountQuery = new Parse.Query("MilestoneAchievements");
    achievementCountQuery.equalTo("isPostponed", false);
    achievementCountQuery.equalTo("isSkipped", false);
    achievementCountQuery.equalTo("standardMilestone", milestone);

    var achievementSkippedCountQuery = new Parse.Query("MilestoneAchievements");
    achievementSkippedCountQuery.equalTo("isSkipped", true);
    achievementSkippedCountQuery.equalTo("standardMilestone", milestone);

    var achievementPostponedCountQuery = new Parse.Query("MilestoneAchievements");
    achievementPostponedCountQuery.equalTo("isPostponed", true);
    achievementPostponedCountQuery.equalTo("standardMilestone", milestone);

    return Parse.Promise.as().then(function() {
        return achievementCountQuery.count();
    }).then(function(count) {
        return updateOrCreateStat(milestone.id,"standardMilestoneNotedCount",count);
    }).then(function() {
        return achievementSkippedCountQuery.count();
    }).then(function(count) {
        return updateOrCreateStat(milestone.id,"standardMilestoneSkippedCount",count);
    }).then(function() {
        return achievementPostponedCountQuery.count();
    }).then(function(count) {
        return updateOrCreateStat(milestone.id,"standardMilestonePostponedCount",count);
    });
};

Parse.Promise.as().then(function () {
    var allBabiesQuery = new Parse.Query("Babies");
    return allBabiesQuery.each(processBaby);
}).then(function () {
    var allStandardMilestoneQuery = new Parse.Query("StandardMilestones");
    return allStandardMilestoneQuery.each(processMilestone);
}).then(function () {
    console.log("Stats calculation completed successfully.");
}, function (error) {
    // Set the job's error status
    console.error("Stats calculation fatally failed : " + JSON.stringify(error));
});
