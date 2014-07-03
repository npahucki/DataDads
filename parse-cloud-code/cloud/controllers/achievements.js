var Achievement = Parse.Object.extend('MilestoneAchievements');
var utils = require("cloud/utils");

exports.show = function (req, res) {
    Parse.Cloud.useMasterKey();
    var achievementId = req.params.id;
    console.log("GOT SHOW REQUEST ID:" + achievementId);
    var query = new Parse.Query(Achievement);
    query.include("standardMilestone");
    query.include("baby");


    query.get(achievementId).then(function (achievement) {
                if(achievement.get("sharedVia") & 1 == 1) {
                    var title = achievement.get("customTitle");
                    var milestone = achievement.get("standardMilestone");
                    var baby = achievement.get("baby");
                    if(!title) title = milestone.get("title");
                    title = utils.replacePronounTokens(title,baby.get("isMale"), "en");
                    var hasImage = achievement.get("attachmentType") && achievement.get("attachmentType").indexOf("image/") == 0;
                    var photoUrl = hasImage ? achievement.get("attachment").url() : null ;
                    res.render('achievements/show', {
                        title: title,
                        completedOn : achievement.get("completedOn"),
                        photoUrl : photoUrl
                    });
                } else {
                    res.send(404,"Achievement is not shared");
                }
            },
            function (error) {
                console.error(JSON.stringify(error));
                res.send(500,"Could not display Achievement");
            });
};