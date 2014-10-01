module.exports.generateWebCompatibleVideosFromMov = function (sourceFile) {
    var requestPromise = new Parse.Promise();

    if(sourceFile.toLowerCase().indexOf(".mov") < 1) {
        requestPromise.reject(new Error("Expected a .mov file!"));
        return requestPromise;
    }

    // TODO: Access Keys!
    var accessKey = 'AKIAITC5ZG4R2F4WU4ZQ';
    var secretKey = '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';
    var Requester = require("cloud/aws/Request.js");
    var requester = new Requester({
        key:accessKey,
        secret:secretKey,
        service:"elastictranscoder",
        region:"us-east-1",
        version:"2012-09-25"
    });



    var requestJson = {
        "Input":{
            "Key":sourceFile
        },
        "Outputs":[
            {
                "Key":sourceFile.replace(".mov", ".webm"),
                "PresetId":"1412174401549-a8giv0"
            }
        ],
        "PipelineId":"1412173550726-nz7h9a"
    };

    requester.request({
        method:"post",
        payload:JSON.stringify(requestJson),
        path:"/2012-09-25/jobs",
        success:function (data) {

            var job = data.Job;
            var jobId = job ? job.Id : null;
            if(jobId) {
                requestPromise.resolve(jobId);
            } else {
                requestPromise.reject({ "message": "Did not get a valid jobId from Amazon", "code": -1, response : data});
            }
        },
        error:function (error) {
            requestPromise.reject(error);
        }
    });

    return requestPromise;
};



