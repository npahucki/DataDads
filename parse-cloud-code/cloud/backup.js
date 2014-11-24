Parse.Cloud.job("backup", function (request, status) {
    console.log("Starting backup Job...");
    var Base64 = require("cloud/utils.js").Base64;

    function backUpClass(className, backupLog) {
        var objects = [];
        var file;
        var fieldName = className.indexOf('_') == 0 ?
                className.substring(1, className.length) :
                className;

        return new Parse.Query(className).each(function(obj){
            objects.push(JSON.stringify(obj));
        }).then( function() {
            var data = {base64: Base64.encode( '{"results": [' + objects.join(',') + ']}' )};
            objects = [];
            return new Parse.File(fieldName, data, "application/json").save();
        }).then( function(file) {
            backupLog.set(fieldName, file);
            return backupLog.save().then(function () {
                console.log(fieldName + " file was saved");
            });
        })
    }

    Parse.Cloud.useMasterKey();
    var _ = require('underscore');
    var classNames = ["MilestoneAchievements", "_User", "_Installation", "Babies", "BabyAssignedTips", "Measurements"];
    var backupLog = new Parse.Object("BackupLog");

    var promise = Parse.Promise.as(true);
    _.each(classNames, function (className) {
        console.log("Going to backup " + className);
        promise = promise.then(function() {
            return backUpClass(className, backupLog);
        })
    });



    promise.then(function () {
        // Set the job's success status
        status.success("Backup complete!");
        }, function (error) {
            // Set the job's error status
            require("cloud/teamnotify").notify("Automated backup failed!", error).then(function () {
                status.error("Back up fatally failed : " + JSON.stringify(error));
            });
    });
});
