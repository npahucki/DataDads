var Achievement = Parse.Object.extend('MilestoneAchievements');
var utils = require("cloud/utils");

exports.show = function (req, res) {
    Parse.Cloud.useMasterKey();
    var achievementId = req.params.id;
    var query = new Parse.Query(Achievement);
    query.include("standardMilestone");
    query.include("baby");


    query.get(achievementId).then(function (achievement) {
                // TODO: Temporary work around to bug in client where sharedVia is not updated when shared via email
                var isShared = true; //achievement.get("sharedVia") > 0;
                if(isShared) {
                    var title = achievement.get("customTitle");
                    var milestone = achievement.get("standardMilestone");
                    var baby = achievement.get("baby");
                    if(!title) title = milestone.get("title");
                    title = utils.replacePronounTokens(title,baby.get("isMale"), "en");
                    var hasImage = achievement.get("attachmentType") && achievement.get("attachmentType").indexOf("image/") == 0;
                    var hasVideo = achievement.get("attachmentType") && achievement.get("attachmentType").indexOf("video/") == 0;

                    if(hasImage) {
                        res.render('achievements/show_photo', {
                            title: title,
                            completedOn : achievement.get("completedOn"),
                            photoUrl : achievement.get("attachment").url()
                        });
                    } else if(hasVideo) {
                        res.render('achievements/show_video', {
                            title: title,
                            completedOn : achievement.get("completedOn"),
                            thumbnailUrl : achievement.get("attachmentThumbnail").url(),
                            videoUrl : achievement.get("attachment").url()
                        });
                    } else {
                        res.render('achievements/show_no_media', {
                            title: title,
                            completedOn : achievement.get("completedOn")
                        });
                    }

                } else {
                    res.send(404,"Achievement is not shared");
                }
            },
            function (error) {
                console.error(JSON.stringify(error));
                res.send(500,"Could not display Achievement");
            });
};