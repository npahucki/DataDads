Parse.Cloud.job("backup", function (request, status) {
    console.log("Starting backup Job...");
    var Base64 = require("cloud/utils.js").Base64;

    function backUpClass(className, backupLog) {
        var objects = [];
        var file;
        var fieldName = className.indexOf('_') == 0 ?
                className.substring(1, className.length) :
                className;
        return new Parse.Query(className).each(function (baby) {
            objects.push(baby);
        }).then(function () {
                    var data = {base64:Base64.encode(JSON.stringify({results:objects}))};
                    file = new Parse.File(fieldName, data, "application/json");
                    return file.save();
                }).then(function () {
                    backupLog.set(fieldName, file);
                    return backupLog.save().then(function () {
                        console.log("Saved " + className);
                    });
                });
    }

    Parse.Cloud.useMasterKey();
    var _ = require('underscore');
    var classNames = ["_User", "_Installation", "Babies", "BabyAssignedTips", "MilestoneAchievements", "Measurements", ""];
    var backupLog = new Parse.Object("BackupLog");
    var promises = [];
    _.each(classNames, function (className) {
        promises.push(backUpClass(className, backupLog));
    });
    Parse.Promise.when(promises).then(function () {
        // Set the job's success status
        status.success("Backup complete!");
    }, function (error) {
        // Set the job's error status
        require("cloud/teamnotify").notify("Automated backup failed!", error).then(function () {
            status.error("Back up fatally failed : " + JSON.stringify(error));
        });
    });
});

