/*
 This script will scan the StandardMilestone table for any items that have the title 'DELETEME' and optionally
 replace any references to that milestone with the id of another one that follows with a colon. For example:
 "DELETEME:1234" - any achievements referring to this standard milestone will be updated to point
 to the standard milestone with the id '1234'. The referred to milestone must exist and all replacements
 must be made successfully before the old milestone is deleted.
 */

var Parse = require('./init_parse').createParse();

var _ = require('underscore');
var prefixToken = "DELETEME";

var deletedCount = 0;
var deletedQuery = new Parse.Query("StandardMilestones");
deletedQuery.startsWith("title", prefixToken);
deletedQuery.select("title");
deletedQuery.each(function (milestoneToDelete) {
    console.log("Processing milestone with id " + milestoneToDelete.id);
    return deleteStandardMilestone(milestoneToDelete).then(function() {
        deletedCount++;
    });
}).then(function () {
    console.log("Hapi Hapi! Deleted " + deletedCount + " milestones");
}, function (error) {
    console.error("Awww shucks: " + JSON.stringify(error));
});

function deleteStandardMilestone(milestone) {
    var title = milestone.get("title");
    var replacementStart = title.indexOf(":", prefixToken.length);
    if (replacementStart > -1) {
        var replacementString = title.substr(replacementStart + 1);
        // verify exists
        console.log("Looking up replacement with id " + replacementString);
        return new Parse.Query("StandardMilestones").get(replacementString).then(function (replacement) {
            return replaceMilestone(milestone, replacement);
        }).then(function () {
                    console.log("Made replacements and now deleting " + milestone.id);
                    return milestone.destroy();
                });
    } else {
        console.log("There was no replacement specified, simply deleting " + milestone.id);
        return milestone.destroy();
    }

}

function replaceMilestone(original, replacement) {
    var achievementsQuery = new Parse.Query("MilestoneAchievements");
    achievementsQuery.equalTo("standardMilestone", original);
    return achievementsQuery.each(function (achievement) {
        achievement.set("standardMilestone", replacement);
        achievement.set("standardMilestoneId", replacement.id);
        console.log("For achievement " + achievement.id + " replacing milestone " +
                original.id + " with " + replacement.id);
        return achievement.save();
    });
}

