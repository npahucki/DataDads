var now = new Date();
var Parse = require('./init_parse').createParse();
var util = require("../cloud/utils");

var query = new Parse.Query("MilestoneAchievements");
query.exists("standardMilestone");
query.include("baby");
query.include("standardMilestone");
query.equalTo("isSkipped", false);
query.equalTo("isPostponed", false);
query.doesNotExist("completionDays");
query.each(function (achievement) {
    var baby = achievement.get("baby");
    var babyDueDate = baby.get("dueDate");
    var completedOn = achievement.get("completionDate");
    var completionDays = Math.round(util.daysBetween(babyDueDate, completedOn));
    console.log("Setting " + achievement.id + " to " + completionDays);
    achievement.set("completionDays", completionDays);
    return achievement.save();

}).then(function () {
    console.log("DONE!")
}, function (error) {
   console.error("Crap! " + JSON.stringify(error));
});


