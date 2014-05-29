var _ = require('underscore');

// Job to move over tips based on user subscription and baby age 
Parse.Cloud.job("tipsAssignment", function(request, status) {
  // Set up to modify user data
  Parse.Cloud.useMasterKey();

  // TOOD: Implement for real
  var tip;
  var tipQuery = new Parse.Query("Tips");
  tipQuery.get("ZM2SiOwVuXfT2BFBjL11HA").then(function(theTip) {
    tip = theTip;
    var query = new Parse.Query("Babies");
    return query.find();
  }).then(function(results) {
    var saveBabyPromises = [];
    _.each(results, function(baby) {
      // Set and save the change
      var relation = baby.relation("currentTips");
      relation.add(tip);
      saveBabyPromises.push(baby.save());
    });
    return Parse.Promise.when(saveBabyPromises);
  }).then(function() {
    // Set the job's success status
    status.success("Tip Assignment completed successfully.");
  }, function(error) {
    // Set the job's error status
    status.error("Tip Assignment failed : " + JSON.stringify(error));
  });
});
  



