var thumbnails = require("cloud/thumbnails.js");


Parse.Cloud.beforeSave("Babies", function(request, response) {

  var baby = request.object;
  if (!baby.dirty("avatarImage")) {
    // No photo provided for the baby
    response.success();
    return;
  }

  thumbnails.makeImageThumbnail(baby.get("avatarImage"), 108, 108, true)
  .then(function(thumbnail) {
    baby.set("avatarImageThumbnail", thumbnail);
  }).then(function(result) {
    response.success();
  }, function(error) {
    response.error(error);
  });
});
