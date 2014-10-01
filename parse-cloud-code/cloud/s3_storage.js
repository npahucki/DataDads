


Parse.Cloud.define("fetchStorageUploadUrl", function (request, response) {
    if(!request.user) {
        response.error(400,"Need user to store file");
        return;
    }

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
    var uniqueId = request.params.uniqueId;
    var userPrefix = request.user.id + "/";
    var method = request.params.method;
    var contentType = request.params.contentType;
    var expiresMinutes = 10;

    var signer = sig.urlSigner(accessKey, secretKey);
    var signedUrl = signer.getUrl(method, bucket, userPrefix + uniqueId,  contentType, expiresMinutes);
    response.success({url: signedUrl});

});


