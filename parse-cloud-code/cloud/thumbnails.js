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
};

