// THIS deletes all the test users that were created for testing in one fell swoop.

var Parse = require('./init_parse').createParse();
var _ = require("underscore");
var archive = {}; // Not used for now.
var objectsToDelete = [];

var query = new Parse.Query("Babies");
query.matches("name", "delete.*", "i");
query.each(function (baby) {
    var user = baby.get("parentUser");
    return deleteUser(user).then(function() {
        console.log("Standby: deleting all objects for user " + user.id);
        return Parse.Object.destroyAll(objectsToDelete);
    }).then(function(){
        objectsToDelete = [];
    });
}).then(function () {
    console.log("All Done!");
}, function (error) {
    console.log("Oh Crap. An Error:" + JSON.stringify(error));
});


function deleteUser(user) {
    archive.User = [];
    return deleteUserInstallations(user, archive)
    .then(function () {
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

    return Parse.Query.or(query1, query2).each(function (followConnection) {
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
        console.log("Processing Baby " + baby.id + " with name '" + baby.get("name") + "'");
        archive.Babies.push(baby.toJSON());
        return Parse.Promise.as().then(function () {
            return deleteBabyObjects(baby, "MilestoneAchievements", archive);
        }).then(function () {
                    return deleteBabyObjects(baby, "BabyAssignedTips", archive);
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



