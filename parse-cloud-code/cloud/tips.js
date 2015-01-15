var DRY_RUN = false; // Does not alter DB, implies DEBUG=true.
var DEBUG = DRY_RUN || false;
var DEFAULT_BATCH_SIZE = 50;

var _= require("underscore");

Parse.Cloud.define("queryMyTips", function (request, response) {
    var babyId = request.params.babyId;
    var showHiddenTips = request.params.showHiddenTips;
    var limit = parseInt(request.params.limit);
    var skip = parseInt(request.params.skip);
    var appVersion = request.params.appVersion;


    var query = new Parse.Query("BabyAssignedTips");
    query.include("tip");
    if (!showHiddenTips) query.equalTo("isHidden", false);
    query.equalTo("baby", {__type:"Pointer", className:"Babies", objectId:babyId});
    query.descending("assignmentDate");
    query.skip(skip);
    query.limit(limit);

    // Keep old behavior for old clients which may have had some bugs in the UI.
    if (appVersion < "1.3") {
        var sevenDaysAgo = new Date(new Date().setDate(new Date().getDate() - 7));
        query.greaterThanOrEqualTo("assignmentDate", sevenDaysAgo);
    }

    query.find().
            then(function (results) {
                // TODO: Remove after not many users are on 1.1
                if (!appVersion || appVersion < "1.1") {
                    results.map(function (assignment) {
                        var tip = assignment.attributes["tip"];
                        tip.attributes["title"] = tip.attributes["title"] + ". " + tip.get("shortDescription");
                    });
                }
                response.success(results);
            }, function (error) {
                response.error(error);
            });
});

Parse.Cloud.define("tipBadgeCount", function (request, response) {
    var babyId = request.params.babyId;
    var showHiddenTips = request.params.showHiddenTips;
    //var appVersion = request.params.appVersion;

    var query = new Parse.Query("BabyAssignedTips");
    if (!showHiddenTips) query.equalTo("isHidden", false);
    query.doesNotExist("viewedOn");
    query.equalTo("baby", {__type:"Pointer", className:"Babies", objectId:babyId});
    query.count().
            then(function (count) {
                response.success({badge : count});
            }, function (error) {
                response.error(error);
            });
});




///////////////////////////////////////////////////////////////////
// Job to move over tips based on user subscription and baby age //
///////////////////////////////////////////////////////////////////
// Basic Logic:
// Get a list of all babies, load the user too
// For each baby, determine delivery rate (if the user is premimum, more frequently, if not once a week).
// See when the last tip was delivered, if within the delivery rate,
//    See if any tips are available based on the baby's age (and later completed milestones (condition))
//    If at least one tip is available
//      create the record in the join table
//      push an alert to the user's phone.

///////////////////////////////////////////////////////////////////

function processSingleBaby(baby, sendPushNotification) {
    var utils = require("cloud/utils");
    var DEFAULT_DELIVERY_INTERVAL_DAYS = 3;
    var PUSH_EXP_SECONDS = 60 * 60 * 24 * (DEFAULT_DELIVERY_INTERVAL_DAYS - 1); // Give up one day before next push (don't flood user)

    // Set up to modify user data
    Parse.Cloud.useMasterKey();

    // Takes a single baby and returns a promise that
    // resolves to a date or nil (if no assignments for baby)
    var findLastAssignmenInfo = function () {
        if (DEBUG) console.log("Getting assignment date for baby '" + baby.id);
        var versionQuery = new Parse.Query(Parse.Installation);
        versionQuery.equalTo("user", baby.get("parentUser"));
        versionQuery.select("appVersion");
        var promise1 = versionQuery.first();

        var lastAssignmentQuery = new Parse.Query("BabyAssignedTips");
        lastAssignmentQuery.include("tip");
        lastAssignmentQuery.descending("assignmentDate");
        lastAssignmentQuery.equalTo("baby", baby);
        var promise2 = lastAssignmentQuery.first();

        var assignmentInfo = {};
        assignmentInfo.assignmentDate = null;
        assignmentInfo.appVersion = null;

        return Parse.Promise.when(promise1, promise2).then(function (installation, assignment) {
            if (installation) {
                assignmentInfo.appVersion = installation.get("appVersion");
                if (DEBUG) console.log("Baby " + baby.id + " has a software version of " + assignmentInfo.appVersion);
            }
            if (assignment) {
                assignmentInfo.assignmentDate = assignment.get("assignmentDate");
                assignmentInfo.tipType = assignment.get("tip").get("tipType");
                if (DEBUG) console.log("Baby " + baby.id + " has an last assignment of " + JSON.stringify(assignmentInfo));
            }

            return Parse.Promise.as(assignmentInfo);
        });
    };

    var findNextTip = function (lastAssignmentInfo) {
        // Ths problem with this is that a single user MAY have multiple versions of the app
        // installed on different devices, so we can't assume that the app version we get here
        // applies to all devices! In any case, since the games are shown in a backward compatible way
        // now, there is no reason not to deliver games as 'tips' to older installs.
        var supportsGames = true; //lastAssignmentInfo.appVersion && lastAssignmentInfo.appVersion >= "1.1";

        // 1 == Normal, 2 == Game
        var minAllowedTipType = 1;
        var maxAllowedTipType = supportsGames ? 2 : 1;
        lastAssignmentInfo.nextTipType = (lastAssignmentInfo.nextTipType || lastAssignmentInfo.tipType) || maxAllowedTipType;
        if (++lastAssignmentInfo.nextTipType > maxAllowedTipType) {
            lastAssignmentInfo.nextTipType = minAllowedTipType;
        }
        var shouldTryAgainIfNoTipFound = lastAssignmentInfo.nextTipType != lastAssignmentInfo.tipType;
        if (DEBUG) console.log("Looking for tip for " + baby.id + " NEXT TipType:" + lastAssignmentInfo.nextTipType);

        innerQuery = new Parse.Query("BabyAssignedTips");
        innerQuery.equalTo("baby", baby);
        innerQuery.limit(1000); // TODO: Will need to fix this once people get over 1000 tips!
        var babyDueDate = baby.get("dueDate");
        var babyAgeInDays = Math.abs(utils.dayDiffFromNow(babyDueDate));
        if (DEBUG) console.log("Baby " + baby.id + " was due " + babyDueDate + " and is " + babyAgeInDays + " days old");
        tipsQuery = new Parse.Query("Tips");
        tipsQuery.greaterThanOrEqualTo("rangeHigh", babyAgeInDays);
        tipsQuery.lessThanOrEqualTo("rangeLow", babyAgeInDays);
        tipsQuery.ascending("rangeHigh,rangeLow");
        // See https://parse.com/questions/trouble-with-nested-query-using-objectid
        tipsQuery.doesNotMatchKeyInQuery("objectId", "tipId", innerQuery);
        tipsQuery.equalTo("tipType", lastAssignmentInfo.nextTipType);

        if (shouldTryAgainIfNoTipFound) {
            return tipsQuery.first().then(function (tip) {
                return tip ? Parse.Promise.as(tip) : findNextTip(lastAssignmentInfo);
            });
        } else {
            return tipsQuery.first();
        }

    };


    var doAssignTip = function (tip) {
        if (DEBUG) console.log("Assigning tip " + tip.id + " for baby " + baby.id);
        var assignment = new Parse.Object("BabyAssignedTips");
        assignment.set("baby", baby);
        assignment.set("isHidden", false);
        assignment.set("tip", tip);
        // See https://parse.com/questions/trouble-with-nested-query-using-objectid
        assignment.set("tipId", tip.id);
        assignment.set("assignmentDate", new Date());
        return DRY_RUN ? Parse.Promise.as(assignment) : assignment.save();
    };

    var pushMessageToUserForBaby = function (tipAssignment, parentUser) {
        if (DEBUG) console.log("Pushing tip assignment " + tipAssignment.id + " to user " + parentUser.id);

        title = tipAssignment.get("tip").get("title");
        // TODO: get languange from parent profile!
        title = utils.replacePronounTokens(title, tipAssignment.get("baby").get("isMale"), "en");
        // IOS allows 256 bytes max
        if (title.length > 100) {
            title = title.substring(0, 100) + "...";
        }

        var pushQuery = new Parse.Query(Parse.Installation);
        pushQuery.equalTo("user", parentUser);
        pushQuery.equalTo("deviceType", "ios");

        if(DRY_RUN) {
            return pushQuery.find().then(function(installations) {
                _.each(installations, function(installation) {
                    console.log("Would push to install Id " + installation.get("installationId") + " for user " + parentUser.id)
                });
            });
        } else {
            return Parse.Push.send({
                where:pushQuery,
                data:{
                    alert:title,
                    cdata:{
                        type : "tip",
                        relatedObjectId:tipAssignment.id
                    },
                    badge:"Increment",
                    sound:"default"
                    //expiration_interval:PUSH_EXP_SECONDS
                }
            });
        }
    };

    var testIfDueForDelivery = function (lastAssignmentInfo) {
        var frequencyDays = DEFAULT_DELIVERY_INTERVAL_DAYS; // TODO: calc based on user is premium or not
        var daysDiff = lastAssignmentInfo && lastAssignmentInfo.assignmentDate ?
                Math.abs(utils.dayDiffFromNow(lastAssignmentInfo.assignmentDate)) : -1;
        if (DEBUG) console.log("For baby " + baby.id + " there are " + daysDiff + " days since last assignment");
        lastAssignmentInfo.needsTipAssignment = (daysDiff == -1 || daysDiff > frequencyDays);
        return Parse.Promise.as(lastAssignmentInfo);
    };

    function isParentEligibleForTip() {
        var parentUserRef = baby.get("parentUser");
        if (parentUserRef) {
            return parentUserRef.fetch().then(function (parentUser) {
                return Parse.Promise.as(parentUser && parentUser.get("email"));
            });

        } else {
            return Parse.Promise.as(false);
        }
    }

    ///////////////////////////////////////////////////////////////
    // Main Method Logic                                         //
    ///////////////////////////////////////////////////////////////

    // Takes a single baby, returns a Promise that
    //  writes an assignment record (if needed)
    //  pushes a notification to the user's phone.
    if (DEBUG) console.log("Processing baby " + baby.id);

    return isParentEligibleForTip().
            then(function (isEligible) {
                if (isEligible) {
                    return findLastAssignmenInfo().
                            then(function (lastAssignmentInfo) {
                                if (DEBUG) console.log("Found last assignmentDate for " + baby.id + " it is " + lastAssignmentInfo.assignmentDate);
                                return testIfDueForDelivery(lastAssignmentInfo);
                            }).
                            then(function (lastAssignmentInfo) {
                                if (lastAssignmentInfo.needsTipAssignment) {
                                    if (DEBUG) console.log("Will attempt to find tip for baby " + baby.id);
                                    return findNextTip(lastAssignmentInfo);
                                }
                            }).
                            then(function (tip) {
                                if (tip) {
                                    if (DEBUG) console.log("Will assign tip " + tip.id + " to baby " + baby.id);
                                    return doAssignTip(tip);
                                } else {
                                    if (DEBUG) console.log("No more eligible tips found for " + baby.id);
                                }
                            }).
                            then(function (tipAssignment) {
                                if (tipAssignment && sendPushNotification) {
                                    if (DEBUG) console.log("Will push message for tip assignment " + tipAssignment.id + " to baby " + baby.id);
                                    var parentUser = baby.get("parentUser");
                                    if (parentUser) {
                                        return pushMessageToUserForBaby(tipAssignment, parentUser);
                                    } else {
                                        console.warn("Skipped notifying baby " + baby.id + " b/c he has no parentUser");
                                    }
                                }
                            }).
                            then(function () {
                                if (DEBUG) console.log("Done processing baby " + baby.id);
                            }, function (error) {
                                console.error("Could not process baby " + baby.id + " Error:" + JSON.stringify(error));
                            });

                } else {
                    if (DEBUG) console.log("Skipped baby " + baby.id + " because parent is not eligible");
                    return Parse.Promise.as(false);
                }
            });

}

// Expects a basic baby query that has limits and conditions set.
function processBabies(babyQuery, sendPushNotification) {
    return processBabiesByBatch(babyQuery, 0, DEFAULT_BATCH_SIZE, sendPushNotification);
}

// Expects a basic baby query that has limits and conditions set.
// This method processes babies in batches of 'batchSize'. The smaller this number
// the longer the total job will take, but the fewer burst resources it will consume.
function processBabiesByBatch(babyQuery, offsetIndex, batchSize, sendPushNotification) {
    if (batchSize > 1000 || batchSize < 1) throw "Can not use batch size of more than 1000 or less than 1";

    babyQuery.include("parentUser");
    babyQuery.select("name", "dueDate", "parentUser", "isMale");
    babyQuery.limit(batchSize);
    babyQuery.skip(offsetIndex);


    var babyPromises = [];
    return babyQuery.find().then(function (babies) {
        _.each(babies, function(baby) {
            babyPromises.push(processSingleBaby(baby, sendPushNotification));
        });
        if(DEBUG) console.log("Processing batch " + offsetIndex + "-" + (offsetIndex + batchSize));
        return Parse.Promise.when(babyPromises);
    }).then(function () {
        // If there are more, process the next batch
        var numberProcessed = arguments.length;
        return numberProcessed < batchSize ? Parse.Promise.as(false) :
                processBabiesByBatch(babyQuery, (offsetIndex + numberProcessed), batchSize, sendPushNotification);

    });
}

Parse.Cloud.job("tipsAssignment", function (request, status) {
    console.log("Starting tipsAssignment job...");
    Parse.Cloud.useMasterKey();
    var batchSize = request.params.batchSize || DEFAULT_BATCH_SIZE;

    return  processBabiesByBatch(new Parse.Query("Babies"), 0, batchSize, true).
            then(function () {
                // Set the job's success status
                status.success("Tip Assignment completed successfully.");
            }, function (error) {
                // Set the job's error status
                status.error("Tip Assignment fatally failed : " + JSON.stringify(error));
            });
});

Parse.Cloud.job("tipsAssignmentSingleBaby", function (request, status) {
    var babyId = request.params.babyId;
    if (!babyId) {
        status.error("The babyId parameter must be specified!");
        return;
    }

    console.log("Starting tipsAssignment job for " + babyId);
    Parse.Cloud.useMasterKey();
    var query = new Parse.Query("Babies");
    query.equalTo("objectId", babyId);
    return processBabies(query, true).
            then(function () {
                // Set the job's success status
                status.success("Tip Assignment completed successfully.");
            }, function (error) {
                // Set the job's error status
                status.error("Tip Assignment fatally failed : " + JSON.stringify(error));
            });
});


module.exports.processBabies = processBabies;
module.exports.processBaby = processSingleBaby;
