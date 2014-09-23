var Achievement = Parse.Object.extend('MilestoneAchievements');
var utils = require("cloud/utils");

exports.show = function (req, res) {
    Parse.Cloud.useMasterKey();
    var achievementId = req.params.id;
    var query = new Parse.Query(Achievement);
    query.include("standardMilestone");
    query.include("baby");


    query.get(achievementId).then(function (achievement) {
                var isShared = achievement.get("sharedVia") > 0;
                if (isShared) {
                    var title = achievement.get("customTitle");
                    var milestone = achievement.get("standardMilestone");
                    var baby = achievement.get("baby");
                    if (!title) title = milestone.get("title");
                    title = utils.replacePronounTokens(title, baby.get("isMale"), "en");
                    var hasImage = achievement.get("attachmentType") && achievement.get("attachmentType").indexOf("image/") == 0;
                    var hasVideo = achievement.get("attachmentType") && achievement.get("attachmentType").indexOf("video/") == 0;

                    if (hasImage) {
                        res.render('achievements/show_photo', {
                            title:title,
                            completedOn:achievement.get("completedOn"),
                            photoUrl:achievement.get("attachment").url()
                        });
                    } else if (hasVideo) {
                        var width = achievement.get("attachmentWidth");
                        var height = achievement.get("attachmentHeight");
                        var orientation = achievement.get("attachmentOrientation");
                        var rotation = 0;
                        switch (orientation) {
                            case 1: // Down.
                                rotation = 180;
                                break;
                            case 2: // Left
                                // Swap height and width
                                height = achievement.get("attachmentWidth");
                                width = achievement.get("attachmentHeight");
                                rotation = 270;
                                break;
                            case 3: // Right
                                // Swap height and width
                                height = achievement.get("attachmentWidth");
                                width = achievement.get("attachmentHeight");
                                rotation = 90;
                                break;
                        }

                        console.log("ORIENTATION:" + orientation +  " WIDTH: " + width + " HEIGHT:" + height + " ROTATE:" + rotation);

                        res.render('achievements/show_video', {
                            title:title,
                            completedOn:achievement.get("completedOn"),
                            thumbnailUrl:achievement.get("attachmentThumbnail").url(),
                            videoUrl:achievement.get("attachment").url(),
                            videoWidth:width,
                            videoHeight:height,
                            videoRotation:rotation
                        });
                    } else {
                        res.render('achievements/show_no_media', {
                            title:title,
                            completedOn:achievement.get("completedOn")
                        });
                    }

                } else {
                    res.send(404, "Achievement is not shared");
                }
            },
            function (error) {
                console.error(JSON.stringify(error));
                res.send(500, "Could not display Achievement");
            });
};