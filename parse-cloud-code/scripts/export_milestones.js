var GENERIC_BABY_ID = "LyOL5AJKa4";
var fs = require('fs');
var now = new Date();
var crypto = require('crypto');
var Parse = require('./init_parse').createParse();

function obfuscateId(idString) {
    return crypto.createHash('md5').update(idString).digest('base64');
}

function csvLineForHeaders() {
    return  "babyId, " +
            "babySex," +
            "babyDueOn," +
            "babyBornOn," +
            "milestoneId, " +
            "milestoneTitle, " +
            "completedOnDay"+
            "\n";
}

function toSimpleDateString(date) {
    return date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate();
}

function csvLineForAchievement(achievement) {
    return  obfuscateId(achievement.get("baby").id) + "," +
            (achievement.get("baby").get("isMale") ? "M" : "F")+ "," +
            toSimpleDateString(achievement.get("baby").get("dueDate")) + "," +
            toSimpleDateString(achievement.get("baby").get("birthDate")) + "," +
            obfuscateId(achievement.id) + "," +
            "\"" + achievement.get("standardMilestone").get("title").replace(/\"/g, "\"\"") + "\"," +
            achievement.get("completionDays") +
            "\n";
}

var fileName = "export-" + now.getFullYear() + "-" + (now.getMonth() + 1) + "-" + now.getDate() + ".csv";
var wstream = fs.createWriteStream(fileName);
var path = fs.realpathSync(fileName);
wstream.on('finish', function () {
  console.log('All Done, file located at ' + path);
});

wstream.write(csvLineForHeaders());
console.log("Writing to output file " + path);
var processedCount = 0;
var query = new Parse.Query("MilestoneAchievements");
query.exists("standardMilestone");
query.include("baby");
query.include("standardMilestone");
query.equalTo("isSkipped", false);
query.equalTo("isPostponed", false);
query.each(function(achievement) {
    if(!achievement.get("standardMilestone")) {
        console.warn("Skipped achievement " + achievement.id + " because it had a null standardMilestone - PLEASE CHECK IT");
    } else if(!achievement.get("baby")) {
        console.warn("Skipped achievement " + achievement.id + " because it had a null baby - PLEASE CHECK IT");
    } else if(achievement.get("baby").id != GENERIC_BABY_ID) {
        wstream.write(csvLineForAchievement(achievement));
        console.log("Processed " + ++processedCount);
    }

}).then(function() {
    wstream.end();
});
