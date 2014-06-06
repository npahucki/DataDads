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
var utils = require("cloud/utils");
var _ = require('underscore');

Parse.Cloud.job("tipsAssignment", function(request, status) {
  var DEFAULT_DELIVERY_INTERVAL_DAYS = 3;
  var PUSH_EXP_SECONDS = 60 * 60 * 24 * (DEFAULT_DELIVERY_INTERVAL_DAYS - 1); // Give up one day before next push (don't flood user)



  // Set up to modify user data
  Parse.Cloud.useMasterKey();

  // Takes a single baby and returns a promise that 
  // resolves to a date or nil (if no assignments for baby)
  var findLastAssignmentDate = function(baby) {
    console.log("Getting assignment date for baby '"+ baby.id);
    var promise = new Parse.Promise();
    // Find the last assignment for the baby
    var lastAssignmentQuery = new Parse.Query("BabyAssignedTips");
    lastAssignmentQuery.descending("assignmentDate");
    lastAssignmentQuery.equalTo("baby", baby);
    lastAssignmentQuery.first().then(function(assignment) {
        var lastAssignmentDate = assignment ? assignment.get("assignmentDate") : null;
        console.log("Baby "+ baby.id + " has an assignment date of "+ lastAssignmentDate);
        promise.resolve(lastAssignmentDate);
    },function(error) {
      console.error("Could not process assignment Date for baby " + baby.id);
      promise.reject(error);
    });
    return promise;
  }

  var findNextTip = function(baby) {
    innerQuery = new Parse.Query("BabyAssignedTips");
    innerQuery.equalTo("baby", baby);
    var babyDueDate = baby.get("dueDate");
    var babyAgeInDays = Math.abs(utils.dayDiffFromNow(babyDueDate));
    console.log("Baby " + baby.id + " was due " + babyDueDate + " as is " + babyAgeInDays + " days old");
    tipsQuery = new Parse.Query("Tips");
    tipsQuery.greaterThanOrEqualTo("rangeHigh", babyAgeInDays);
    tipsQuery.lessThanOrEqualTo("rangeLow", babyAgeInDays);
    tipsQuery.ascending("rangeHigh,rangeLow");
    // See https://parse.com/questions/trouble-with-nested-query-using-objectid
    tipsQuery.doesNotMatchKeyInQuery("objectId","tipId", innerQuery);
    return tipsQuery.first();
  }


  var doAssignTip = function(tip, baby) {
    console.log("Assigning tip " + tip.id + " for baby " + baby.id);
    var assignment = new Parse.Object("BabyAssignedTips");
    assignment.set("baby", baby);
    assignment.set("isHidden", false);
    assignment.set("tip", tip);
    // See https://parse.com/questions/trouble-with-nested-query-using-objectid
    assignment.set("tipId", tip.id);
    assignment.set("assignmentDate", new Date());
    return assignment.save();
  }

  var pushMessageToUserForBaby = function(tipAssignment, parentUser) {
    console.log("Pushing tip assignment " + tipAssignment.id + " to user " + parentUser.id);
    title = tipAssignment.get("tip").get("title");
    console.log("Old title is long :" + title.length);
    // IOS allows 256 bytes max
    if(title.length > 100) {
        title = title.substring(0, 100) + "...";
    console.log("New Title is :" + title);
    }

    var pushQuery = new Parse.Query(Parse.Installation);
    pushQuery.equalTo("user", parentUser);
    pushQuery.equalTo("deviceType", "ios");
    return Parse.Push.send({
        where: pushQuery,
        data: {
          alert: title,
          cdata : { "tipAssignmentId" : tipAssignment.id },
          badge : "Increment",
          sound : "default",
          expiration_interval: PUSH_EXP_SECONDS
        }
      });
  }

  var testIfDueForDelivery = function(baby,lastAssignmentDate) {
    var frequencyDays = DEFAULT_DELIVERY_INTERVAL_DAYS; // TODO: calc based on user is premium or not
    var daysDiff = lastAssignmentDate == null ? -1 : Math.abs(utils.dayDiffFromNow(lastAssignmentDate));
    console.log("For baby "+ baby.id + " there are "+ daysDiff +" days since last assignment");
    if(daysDiff == -1 || daysDiff > frequencyDays) return Parse.Promise.as(true);
  }

  // Takes a single baby, returns a Promise that 
  //  writes an assignment record (if needed)
  //  pushes a notification to the user's phone. 
  var processSingleBaby = function(baby) {
    console.log("Processing baby "+ baby.id);
    return findLastAssignmentDate(baby).
    then(function(lastAssignmentDate) {
          console.log("Found last assignmentDate for "+ baby.id + " it is " + lastAssignmentDate);
          return testIfDueForDelivery(baby,lastAssignmentDate);
    }).
    then(function(needsTipAssignment){
        if(needsTipAssignment) {
            console.log("Will attempt to find tip for baby "+ baby.id);
            return findNextTip(baby);
        }
    }).
    then(function(tip){
        if(tip) {
            console.log("Will assign tip " + tip.id + " to baby "+ baby.id);
            return doAssignTip(tip,baby);
         } else {
            console.log("No more eligible tips found for " + baby.id);
         }
    }).
    then(function(tipAssignment) {
        if(tipAssignment) {
            console.log("Will push message for tip assignment " + tipAssignment.id +" to baby "+ baby.id);
            return pushMessageToUserForBaby(tipAssignment, baby.get("parentUser"));
        }
    }).
    then(function(){
      console.log("Done processing baby " + baby.id);
    }, function(error) {
        console.error("Could not process baby " + baby.id + " Error:" + JSON.stringify(error));
    });
  }


  

  console.log("Starting tipsAssignment job...")
  var babyQuery = new Parse.Query("Babies");
  // TODO: Filter by active babies/users + exclude babies over 5 years old?
  babyQuery.limit(1000); // NOTE: Max is 1000, when we get over this, we will need to find a better way to query
  babyQuery.include("parentUser");
  babyQuery.select("name","dueDate","parentUser");
  console.log("Doing query lookup..");
  babyQuery.find().then(function(babies) {
    //console.log("Babies query result " + JSON.stringify(babies));
    console.log("Found " + babies.length + " babies to process");
    // Process each baby in parrallel 
    var babyPromises = [];
    _.each(babies, function(baby) {
      babyPromises.push(processSingleBaby(baby));
    });
    return Parse.Promise.when(babyPromises);
  }).then(function() {
    // Set the job's success status
    status.success("Tip Assignment completed successfully.");
  }, function(error) {
    // Set the job's error status
    status.error("Tip Assignment fatally failed : " + JSON.stringify(error));
  });

 });






 Parse.Cloud.job("convertBadObjectIdSymbols", function(request, status) {
  //'use strict';
  console.log ("Starting cleanup of ids");

  // Set up to modify user data
  Parse.Cloud.useMasterKey();
  var promises = [];

  var achievementsQuerySlash = new Parse.Query("MilestoneAchievements");
  achievementsQuerySlash.contains("standardMilestoneId","/");
  var achievementsQueryPlus = new Parse.Query("MilestoneAchievements");
  achievementsQueryPlus.contains("standardMilestoneId","+");


  var achievementsQuery = Parse.Query.or(achievementsQuerySlash,achievementsQueryPlus);
  achievementsQuery.limit(1000); // MAX
  achievementsQuery.ascending("createdAt");
  achievementsQuery.find().then(function(achievements) {
    _.each(achievements, function(achievement) {
      var milestone = achievement.get('standardMilestone');
      if(milestone.id.indexOf("+") >= 0 || milestone.id.indexOf("/") >= 0) {
        milestone.id = milestone.id.replace(new RegExp("\\/", "g"),"0");
        milestone.id = milestone.id.replace(new RegExp("\\+", "g"),"1");
        achievement.set('standardMilestone',milestone);
        achievement.set('standardMilestoneId',milestone.id);
        promises.push(achievement.save());
      }
    });

    console.log("Saving " + promises.length + " objects!!");
    return Parse.Promise.when(promises);
  }).then(function() {
    // Set the job's success status
    console.log ("Fixed ids!");
    status.success("Fixed all ids");
  }, function(error) {
    // Set the job's error status
    status.error("Failed to fix ids : " + JSON.stringify(error));
  });

});