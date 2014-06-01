var Image = require("parse-image");

var makeImageThumbnail = function(parseFile, width, height) {
  return Parse.Cloud.httpRequest({
    url: parseFile.url()
  }).then(function(response) {
    var image = new Image();
    return image.setData(response.buffer);
  }).then(function(image) {
    return image.scale({
      width: width,
      height: height
    });
  }).then(function(image) {
    return image.setFormat("JPEG");
  }).then(function(image) {
    return image.data();
  }).then(function(buffer) {
    var base64 = buffer.toString("base64");
    var thumbnail = new Parse.File("thumbnail.jpg", { base64: base64 });
    return thumbnail.save();
  });
}


Parse.Cloud.beforeSave("MilestoneAchievements", function(request, response) {
  var achievement = request.object;
  var isImage = achievement.get("attachmentType") && achievement.get("attachmentType").indexOf("image/") == 0;
  var needThumbnail = achievement.dirty("attachment");
  if (!isImage || !needThumbnail) {
    response.success();
    return;
  }

  makeImageThumbnail(achievement.get("attachment"), 108, 108)
  .then(function(thumbnail) {
    achievement.set("attachmentThumbnail", thumbnail);
  }).then(function(result) {
    response.success();
  }, function(error) {
    response.error(error);
  });
});


Parse.Cloud.beforeSave("Babies", function(request, response) {

  var baby = request.object;
  if (!baby.dirty("avatarImage")) {
    // No photo provided for the baby
    response.success();
    return;
  }

  makeImageThumbnail(baby.get("avatarImage"), 108, 108)
  .then(function(thumbnail) {
    baby.set("avatarImageThumbnail", thumbnail);
  }).then(function(result) {
    response.success();
  }, function(error) {
    response.error(error);
  });
});
