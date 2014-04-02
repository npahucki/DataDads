Parse.Cloud.define("queryMyMilestones", function(request, response) {

 // TODO: May need to look up baby and verify against user for security!

 var babyId = request.params.babyId;
 var rangeDays =  parseInt(request.params.rangeDays);
 var limit = parseInt(request.params.limit);
 var skip = parseInt(request.params.skip);

 if(!babyId || rangeDays < 1) {
     response.error("Invalid query, need babyId and rangeDays parameters.");
     return;
 }
 //console.log("Request for queryMyMilestones with babyId:" + babyId + " rangeDays:" + rangeDays + " limit:" + limit + " skip:" + skip);

 innerQuery = new Parse.Query("MilestoneAchievements");
 innerQuery.equalTo("baby", {__type: "Pointer", className: "Babies", objectId : babyId});
 
 query = new Parse.Query("StandardMilestones");
 query.greaterThanOrEqualTo("rangeHigh", rangeDays);
 query.lessThanOrEqualTo("rangeLow", rangeDays);
 // Bit if a hack here, using string column here : See https://parse.com/questions/trouble-with-nested-query-using-objectid
 query.doesNotMatchKeyInQuery("objectId", "standardMilestoneId", innerQuery);
 query.ascending("rangeHigh");
 query.limit(limit);
 query.skip(skip);
 query.find({
   success: function(results) {
     response.success(results);
   },
   error: function(error) {
     response.error(error);
   }
 });
});
