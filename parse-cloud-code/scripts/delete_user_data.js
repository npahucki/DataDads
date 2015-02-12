var DRY_RUN = false;

var Parse = require('./init_parse').createParse();
var fs = require('fs');
var readline = require('readline');

var archive = {}; // makes a backup of the user's data just in case.
var objectsToDelete = [];

var rl = readline.createInterface({
    input:process.stdin,
    output:process.stdout
});

rl.question("Enter userid to delete, or blank to cancel. Please BACKUP before running!", function (userId) {
    rl.close();
    if (userId) {
        var basePath = "archived_users/";
        if (!fs.existsSync(basePath)) fs.mkdirSync(basePath);
        var path = basePath + userId + "/";
        if (fs.existsSync(path)) {
            console.error("A backup for " + userId + " already exists, delete it first");
            process.exit();
        }

        deleteUser(userId).then(function () {
            return saveArchivedObjects(path);
        }).then(function () {
                    if (DRY_RUN) {
                        console.log("DRY_RUN mode, nothing deleted from Parse!");
                        return Parse.Promise.as();
                    } else {
                        console.log("Standby: deleting now....");
                        return Parse.Object.destroyAll(objectsToDelete);
                    }
                }).then(function () {
                    console.log("All Done. Archive file located at: " + path);
                },function (error) {
                    console.log("Failed to delete user " + userId + " Reason:" + JSON.stringify(error));
                }).always(function () {
                    process.exit();
                });
    } else {
        console.log("Canceled at your request");
        process.exit();
    }
});

function saveArchivedObjects(path) {
    fs.mkdirSync(path);
    for (var prop in archive) {
        if (archive.hasOwnProperty(prop)) {
            var fileName = prop + ".json";
            var exportObject = { results:archive[prop]};
            fs.writeFileSync(path + fileName, JSON.stringify(exportObject, null, 2));
        }
    }
    return Parse.Promise.as(true);
}

function deleteUser(userId) {
    archive.User = [];
    var user = null;
    return new Parse.Query(Parse.User).get(userId).then(function (u) {
        user = u;
        console.log("Will delete User with email:" + user.get("email") + " and name:" + user.get("fullName"));
    }).then(function () {
        return deleteUserInstallations(user, archive);
    }).then(function () {
        return deleteUserFollowConnections(user, archive);
    }).then(function () {
        return deleteUserTransactions(user, archive);
    }).then(function () {
        return deleteUserBabies(user, archive);
    }).then(function () {
        archive.User.push(user.toJSON());
        objectsToDelete.push(user);
    });
}


function deleteUserInstallations(user, archive) {
    archive.Installation = [];
    var query = new Parse.Query(Parse.Installation);
    query.equalTo("user", user);
    return query.each(function (installation) {
        archive.Installation = installation.toJSON();
        console.log("Will delete Installation  with id " + installation.id);
        objectsToDelete.push(installation);
    });
}

function deleteUserTransactions(user, archive) {
    archive.PurchaseTransactions = [];
    var query = new Parse.Query("PurchaseTransactions");
    query.equalTo("user", user);
    return query.each(function (transaction) {
        archive.PurchaseTransactions = transaction.toJSON();
        console.log("Will delete PurchaseTransaction with id " + transaction.id);
        objectsToDelete.push(transaction);
    });
}

function deleteUserFollowConnections(user, archive) {
    archive.FollowConnections = [];
    var query1 = new Parse.Query("FollowConnections");
    query1.equalTo("user1", user);
    var query2 = new Parse.Query("FollowConnections");
    query2.equalTo("user2", user);

    return Parse.Query.or(query1,query2).each(function (followConnection) {
        archive.FollowConnections = followConnection.toJSON();
        console.log("Will delete FollowConnection with id " + followConnection.id);
        objectsToDelete.push(followConnection);
    });
}


function deleteUserBabies(user, archive) {
    archive.Babies = [];
    var query = new Parse.Query("Babies");
    query.equalTo("parentUser", user);
    return query.each(function (baby) {
        console.log("Processing Baby " + baby.id + " with name '"+ baby.get("name") +"'");
        archive.Babies.push(baby.toJSON());
        return Parse.Promise.as().then(function () {
            return deleteBabyObjects(baby, "MilestoneAchievements", archive);
        }).then(function () {
            return deleteBabyObjects(baby, "BabyAssignedTips", archive);
        }).then(function () {
            return deleteBabyObjects(baby, "Measurements", archive);
        }).then(function () {
            return deleteBabyObjects(baby, "Measurements", archive);
        }).then(function () {
            console.log("Will delete Baby with id " + baby.id);
            objectsToDelete.push(baby);
        });
    });
}

function deleteBabyObjects(baby, objectName, archive) {
    if (!archive[objectName]) {
        archive[objectName] = [];
    }
    console.log("Will delete " + objectName + " objects for baby " + baby.id);
    var query = new Parse.Query(objectName);
    query.equalTo("baby", baby);
    return query.each(function (object) {
        archive[objectName].push(object.toJSON());
        objectsToDelete.push(object);
        console.log("Will delete " + objectName + " with id " + object.id);
    });
}



