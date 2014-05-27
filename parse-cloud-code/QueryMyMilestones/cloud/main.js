Parse.Cloud.define("queryMyMilestones", function(request, response) {

 // TODO: May need to look up baby and verify against user for security!

 var babyId = request.params.babyId;
 var timePeriod = request.params.timePeriod;
 var rangeDays =  parseInt(request.params.rangeDays);
 var limit = parseInt(request.params.limit);
 var skip = parseInt(request.params.skip);

 if(!babyId || rangeDays < 0) {
     response.error("Invalid query, need babyId and rangeDays parameters.");
     return;
 }
 //console.log("Request for queryMyMilestones with babyId:" + babyId + " rangeDays:" + rangeDays + " limit:" + limit + " skip:" + skip);

 innerQuery = new Parse.Query("MilestoneAchievements");
 innerQuery.equalTo("baby", {__type: "Pointer", className: "Babies", objectId : babyId});
 innerQuery.exists("standardMilestoneId");
 //innerQuery.select(["standardMilestoneId"]);
 
 query = new Parse.Query("StandardMilestones");
 
 if(timePeriod == "future") {
	 query.greaterThanOrEqualTo("rangeHigh", rangeDays);
	 query.ascending("rangeHigh,rangeLow");
 } else if (timePeriod == "past") {
	 query.lessThanOrEqualTo("rangeHigh", rangeDays);
	 query.descending("rangeHigh,rangeLow");
 } else {
     response.error("Invalid query, unknown timePeriod '" + timePeriod + "'");
     return;
 }
 
 //query.lessThanOrEqualTo("rangeLow", rangeDays);
 // Bit if a hack here, using string column here : See https://parse.com/questions/trouble-with-nested-query-using-objectid
 query.doesNotMatchKeyInQuery("objectId", "standardMilestoneId", innerQuery);
 query.limit(limit);
 query.skip(skip);
 query.select(["title","rangeHigh","rangeLow"])
 query.find({
   success: function(results) {
     response.success(results);
   },
   error: function(error) {
     response.error(error);
   }
 });
});



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
       console.log("TOTAL RESULT " + result);
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
       console.log("SCORE RESULT " + result);
       scoreCount = result;
     },
     error: function(error) {
       response.error(error);
     }
   }));
   // Return a new promise that is resolved when all of the queries are finished.
   return Parse.Promise.when(promises);
 }).then(function() {
   console.log("BOTH QUERIES DONE"); 
   // Need at least mine and one other to compare
   var p = totalCount < 2 ? -1 : (scoreCount / totalCount) * 100;
   console.log("P=" + p); 
   response.success(p);
   });
});

