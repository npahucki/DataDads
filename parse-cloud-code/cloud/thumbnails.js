var Image = require("parse-image");

module.exports.makeImageThumbnail = function (parseFile, width, height, keepAspectRatio) {
    return Parse.Cloud.httpRequest({
        url:parseFile.url()
    }).then(function (response) {
        var image = new Image();
        return image.setData(response.buffer);
    }).then(function (image) {
         // Don't try to scale already small images.
         if(image.width() < width || image.height() < height) {
             Parse.Promise.as(image);
         }

         if (keepAspectRatio) {
            var ratio = image.width() / image.height();
            if (image.width > image.height) {
                // Fill the full height, ok that the width is over
                width = width * ratio;
            } else {
                // Fill the full width
                height = height * ratio;
            }
        }

        return image.scale({
            width:width,
            height:height
        });
    }).then(function (image) {
        return image.setFormat("JPEG");
    }).then(function (image) {
        return image.data();
    }).then(function (buffer) {
        var base64 = buffer.toString("base64");
        var thumbnail = new Parse.File("thumbnail.jpg", { base64:base64 });
        return thumbnail.save();
    });
};

