function generateSignedS3Url(method, filePath, contentType) {
    var util = require("cloud/utils.js");
    var awsInfo = util.awsVideoEnv();
    var sig = require('cloud/s3_signature.js');
    var signer = sig.urlSigner(awsInfo.accessKey, awsInfo.secretKey);
    return signer.getUrl(method, awsInfo.bucket, filePath,  contentType, 10);
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


