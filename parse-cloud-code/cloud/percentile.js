/////////////////////////// Percentile Calculations //////////////////////
Parse.Cloud.define("percentileRanking", function(request, response) {
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
   promises.push(countQuery.count({
     success: function(result) {
       totalCount = result;
     },
     error: function(error) {
       response.error(error);
     }
   }));
   
   scoreQuery = new Parse.Query("MilestoneAchievements");
   scoreQuery.equalTo("standardMilestoneId", milestoneId);
   scoreQuery.exists("completionDays");
   scoreQuery.lessThan("completionDays", completionDays);
   promises.push(scoreQuery.count({
     success: function(result) {
       scoreCount = result;
     },
     error: function(error) {
       response.error(error);
     }
   }));
   // Return a new promise that is resolved when all of the queries are finished.
   return Parse.Promise.when(promises);
 }).then(function() {
   // Need at least mine and one other to compare
   var p = totalCount < 2 ? -1 : (scoreCount / totalCount) * 100;
   response.success(p);
   });
});
