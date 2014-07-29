/////////////////////////// Percentile Calculations //////////////////////
Parse.Cloud.define("percentileRanking", function(request, response) {

 Parse.Cloud.useMasterKey();
 var milestoneId = request.params.milestoneId;
 var completionDays = parseInt(request.params.completionDays);

 if(completionDays < 0 || !milestoneId) {
     response.error("Invalid query, need completionDays and milestoneId parameters.");
     return;
 }

 var totalCount = -1;
 var scoreCount = -1;

 Parse.Promise.as().then(function() {
   var promises = [];

   // Run both queries in parralel
   countQuery = new Parse.Query("MilestoneAchievements");
   countQuery.equalTo("standardMilestoneId", milestoneId);
   countQuery.exists("completionDays");
   promises.push(countQuery.count().then(function(result){
       totalCount = result;
   }));

   scoreQuery = new Parse.Query("MilestoneAchievements");
   scoreQuery.equalTo("standardMilestoneId", milestoneId);
   scoreQuery.exists("completionDays");
   // NOTE: A completion day greater represents a lower score. 
   scoreQuery.greaterThan("completionDays", completionDays);
   promises.push(scoreQuery.count().then(function(result){
       scoreCount = result;
   }));
   return Parse.Promise.when(promises);
 }).then(function() {
   console.log("Score Count=" + scoreCount + " Total Count=" + totalCount);
   // Need at least mine and one other to compare
   if(totalCount==0) {
    // Nothing to compare to, just say that you are ahead of 100% of babies.
    p = 99.99;
   } else {
    p = (scoreCount / totalCount) * 100;
   }
   response.success(p);
   }, function(error){
    response.error(error);
   });
});
