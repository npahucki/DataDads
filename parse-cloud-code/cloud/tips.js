Parse.Cloud.define("queryMyTips", function (request, response) {
    var babyId = request.params.babyId;
    var showHiddenTips = request.params.showHiddenTips;
    var limit = parseInt(request.params.limit);
    var skip = parseInt(request.params.skip);

    var userIsPremium = false; // TODO: load from user profile, or table of user purchases

    var query = new Parse.Query("BabyAssignedTips");
    query.include("tip");
    if (!showHiddenTips) query.equalTo("isHidden", false);
    if (!userIsPremium) {
        var sevenDaysAgo = new Date(new Date().setDate(new Date().getDate() - 7));
        query.greaterThanOrEqualTo("assignmentDate", sevenDaysAgo);
    }
    query.equalTo("baby", {__type:"Pointer", className:"Babies", objectId:babyId});
    query.descending("assignmentDate");
    query.skip = skip;
    query.limit = limit;
    query.find().
            then(function (results) {
                response.success(results);
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
    var findLastAssignmentDate = function (baby) {
        console.log("Getting assignment date for baby '" + baby.id);
        var promise = new Parse.Promise();
        // Find the last assignment for the baby
        var lastAssignmentQuery = new Parse.Query("BabyAssignedTips");
        lastAssignmentQuery.descending("assignmentDate");
        lastAssignmentQuery.equalTo("baby", baby);
        lastAssignmentQuery.first().then(function (assignment) {
            var lastAssignmentDate = assignment ? assignment.get("assignmentDate") : null;
            //console.log("Baby " + baby.id + " has an assignment date of " + lastAssignmentDate);
            promise.resolve(lastAssignmentDate);
        }, function (error) {
            console.error("Could not process assignment Date for baby " + baby.id);
            promise.reject(error);
        });
        return promise;
    };

    var findNextTip = function (baby) {
        innerQuery = new Parse.Query("BabyAssignedTips");
        innerQuery.equalTo("baby", baby);
        var babyDueDate = baby.get("dueDate");
        var babyAgeInDays = Math.abs(utils.dayDiffFromNow(babyDueDate));
        //console.log("Baby " + baby.id + " was due " + babyDueDate + " as is " + babyAgeInDays + " days old");
        tipsQuery = new Parse.Query("Tips");
        tipsQuery.equalTo("tipType", 1);
        tipsQuery.greaterThanOrEqualTo("rangeHigh", babyAgeInDays);
        tipsQuery.lessThanOrEqualTo("rangeLow", babyAgeInDays);
        tipsQuery.ascending("rangeHigh,rangeLow");
        // See https://parse.com/questions/trouble-with-nested-query-using-objectid
        tipsQuery.doesNotMatchKeyInQuery("objectId", "tipId", innerQuery);
        return tipsQuery.first();
    };


    var doAssignTip = function (tip, baby) {
        //console.log("Assigning tip " + tip.id + " for baby " + baby.id);
        var assignment = new Parse.Object("BabyAssignedTips");
        assignment.set("baby", baby);
        assignment.set("isHidden", false);
        assignment.set("tip", tip);
        // See https://parse.com/questions/trouble-with-nested-query-using-objectid
        assignment.set("tipId", tip.id);
        assignment.set("assignmentDate", new Date());
        return assignment.save();
    };

    var pushMessageToUserForBaby = function (tipAssignment, parentUser) {
        //console.log("Pushing tip assignment " + tipAssignment.id + " to user " + parentUser.id);
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
        return Parse.Push.send({
            where:pushQuery,
            data:{
                alert:title,
                cdata:{ "tipAssignmentId":tipAssignment.id },
                badge:"Increment",
                sound:"default",
                expiration_interval:PUSH_EXP_SECONDS
            }
        });
    };

    var testIfDueForDelivery = function (baby, lastAssignmentDate) {
        var frequencyDays = DEFAULT_DELIVERY_INTERVAL_DAYS; // TODO: calc based on user is premium or not
        var daysDiff = lastAssignmentDate == null ? -1 : Math.abs(utils.dayDiffFromNow(lastAssignmentDate));
        console.log("For baby " + baby.id + " there are " + daysDiff + " days since last assignment");
        if (daysDiff == -1 || daysDiff > frequencyDays) return Parse.Promise.as(true);
    };

    function isParentEligibleForTip(baby) {
        var parentUserRef = baby.get("parentUser");
        if(parentUserRef) {
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
    //console.log("Processing baby " + baby.id);

    return isParentEligibleForTip(baby).
            then(function (isEligible) {
                if (isEligible) {
                    return findLastAssignmentDate(baby).
                            then(function (lastAssignmentDate) {
                                //console.log("Found last assignmentDate for " + baby.id + " it is " + lastAssignmentDate);
                                return testIfDueForDelivery(baby, lastAssignmentDate);
                            }).
                            then(function (needsTipAssignment) {
                                if (needsTipAssignment) {
                                    //console.log("Will attempt to find tip for baby " + baby.id);
                                    return findNextTip(baby);
                                }
                            }).
                            then(function (tip) {
                                if (tip) {
                                    //console.log("Will assign tip " + tip.id + " to baby " + baby.id);
                                    return doAssignTip(tip, baby);
                                } else {
                                    //console.log("No more eligible tips found for " + baby.id);
                                }
                            }).
                            then(function (tipAssignment) {
                                if (tipAssignment && sendPushNotification) {
                                    //console.log("Will push message for tip assignment " + tipAssignment.id + " to baby " + baby.id);
                                    var parentUser = baby.get("parentUser");
                                    if (parentUser) {
                                        return pushMessageToUserForBaby(tipAssignment, parentUser);
                                    } else {
                                        console.warn("Skipped baby " + baby.id + " b/c he has no parentUser");
                                    }
                                }
                            }).
                            then(function () {
                                console.log("Done processing baby " + baby.id);
                            }, function (error) {
                                console.error("Could not process baby " + baby.id + " Error:" + JSON.stringify(error));
                            });

                } else {
                    console.log("Skipped baby " + baby.id + " because parent is not eligible");
                    return Parse.Promise.as(false);
                }
            });

}

// Expects a basic baby query that has limits and conditions set.
var processBabies = function (babyQuery, sendPushNotification) {
    babyQuery.include("parentUser");
    babyQuery.select("name", "dueDate", "parentUser", "isMale");
    var babyPromises = [];
    return babyQuery.each(function (baby) {
        // Process each baby in parrallel
        babyPromises.push(processSingleBaby(baby, sendPushNotification));
    }).then(function () {
        return Parse.Promise.when(babyPromises);
    });
};


Parse.Cloud.job("tipsAssignment", function (request, status) {
    console.log("Starting tipsAssignment job...");
    Parse.Cloud.useMasterKey();
    return processBabies(new Parse.Query("Babies"), true).
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
