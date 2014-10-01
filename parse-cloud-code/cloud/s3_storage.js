function generateSignedS3Url(method, filePath, contentType) {
    var util = require("cloud/utils.js");

    var bucket, accessKey, secretKey;
    // Note it would be great to keep these in COnfig, but it's not secure.
    if(util.isDev()) {
        bucket = "dp-mf-media-dev";
        accessKey = "AKIAJRGMQXTMWZAS63EQ";
        secretKey = "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";
    } else {
        bucket = "dp-mf-media-prod";
        accessKey = "AKIAJVJAO4WVS4INUGUA";
        secretKey = "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";
    }

    var sig = require('cloud/s3_signature.js');
    var signer = sig.urlSigner(accessKey, secretKey);
    return signer.getUrl(method, bucket, filePath,  contentType, 10);
}


module.exports.generateSignedGetS3Url = function(filePath) {
    return generateSignedS3Url("GET",filePath);
};

Parse.Cloud.define("fetchStorageUploadUrl", function (request, response) {
    if(!request.user) {
        response.error(400,"Need user to store file");
        return;
    }

    var filePath = request.user.id + "/" + request.params.uniqueId;
    response.success({url: generateSignedS3Url(request.params.method, filePath, request.params.contentType)});
});


