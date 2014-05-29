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

  var pushMessageToUserForBaby = function(tipAssignment) {
    console.log("Pushed tip assignment " + JSON.stringify(tipAssignment));
    return Parse.Promise.as("Pushed!");
  }

  var testIfDueForDelivery = function(baby,lastAssignmentDate) {
    var frequencyDays = 7; // TODO: calc based on user is premium or not
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
            console.log("Will push message for tip assignment " + tipAssignment.id +"to "+ baby.id);
            return pushMessageToUserForBaby(tipAssignment);
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
  babyQuery.include("parentUser");
  babyQuery.select("name","dueDate");
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