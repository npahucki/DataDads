var now = new Date();
var Parse = require('./init_parse').createParse();
var util = require("../cloud/utils");

var achievementCount = 0;
var anomalyCount = 0;

var query = new Parse.Query("MilestoneAchievements");
query.exists("completionDays");
query.notEqualTo("baby", {__type:"Pointer", className:"Babies", objectId:"LyOL5AJKa4"}); // Generic baby.
query.include("baby");
query.each(function (achievement) {
    achievementCount++;
    var baby = achievement.get("baby");
    var babyDueDate = baby.get("dueDate");
    var completedOn = achievement.get("completionDate");
    var completionDays = achievement.get("completionDays");
    var calcCompletionDays = Math.round(util.daysBetween(babyDueDate, completedOn)) +1 ;

//    if(completionDays < calcCompletionDays - 1 && completionDays > calcCompletionDays + 1) {
    if(completionDays < calcCompletionDays - 5 || completionDays > calcCompletionDays + 5) {
        anomalyCount++;
        console.error("Achievement " + achievement.id + " has a completionDays of " + completionDays +
                " when we calculated " + calcCompletionDays + ". DueDate:" + babyDueDate + " CompletedOn:" + completedOn);
    }
}).then(function () {
            console.log("DONE! Tested " + achievementCount + " users and found " + anomalyCount + " problems. " +
                    ((anomalyCount/achievementCount) * 100) + "% of completionDays have problems.")
}, function (error) {
   console.error("Crap! " + JSON.stringify(error));
});


