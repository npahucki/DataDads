function createRequester() {
    var util = require("cloud/utils.js");
    var awsInfo = util.awsVideoEnv();

    var Requester = require("cloud/aws/Request.js");
    return new Requester({
        key:awsInfo.accessKey,
        secret:awsInfo.secretKey,
        service:"elastictranscoder",
        region:"us-east-1",
        version:"2012-09-25"
    });
}

function submitRequest(request) {
    var requester = createRequester();
    var requestPromise = new Parse.Promise();
    requester.request({
        method:"post",
        payload:JSON.stringify(request),
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
}


module.exports.generateWebCompatibleVideosFromMov = function (sourceFile) {
    var mp4PresetId = "1412264536088-p35kxu";
    var webmPresetId = "1412267614000-co1w70";

    if(sourceFile.toLowerCase().indexOf(".mov") < 1) {
        requestPromise.reject(new Error("Expected a .mov file!"));
        return requestPromise;
    }

    var util = require("cloud/utils.js");
    var pipelineId = util.awsVideoEnv().webVideoPipelineId;
    var mp4RequestJson = {
        "Input":{
            "Key":sourceFile
        },
        "Outputs":[
            {
                "Key":sourceFile.replace(".mov", ".mp4"),
                "PresetId":mp4PresetId
            }
        ],
        "PipelineId":pipelineId
    };

    var webmRequestJson = {
        "Input":{
            "Key":sourceFile
        },
        "Outputs":[
            {
                "Key":sourceFile.replace(".mov", ".webm"),
                "PresetId":webmPresetId
            }
        ],
        "PipelineId":pipelineId
    };

    return Parse.Promise.when(submitRequest(mp4RequestJson), submitRequest(webmRequestJson));
};



