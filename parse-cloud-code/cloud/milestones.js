var search = require("cloud/search.js");

Parse.Cloud.define("queryMyMilestones", function (request, response) {

    // TODO: May need to look up baby and verify against user for security!
    var babyId = request.params.babyId;
    var babySex = request.params.babyIsMale ? 1 : 0;
    var parentSex = request.params.parentIsMale ? 1 : 0;
    var timePeriod = request.params.timePeriod;
    var rangeDays = parseInt(request.params.rangeDays);
    var limit = parseInt(request.params.limit);
    var skip = parseInt(request.params.skip);
    var filter = request.params.filter;

    if (!babyId || rangeDays < 0) {
        response.error("Invalid query, need babyId and rangeDays parameters.");
        return;
    }


    innerQuery = new Parse.Query("MilestoneAchievements");
    innerQuery.equalTo("baby", {__type:"Pointer", className:"Babies", objectId:babyId});
    innerQuery.exists("standardMilestoneId");
    innerQuery.select(["standardMilestoneId"]);
    innerQuery.limit(1000); // NOTE: if we start getting over 1000 achievements, this is not going to work!!!

    query = new Parse.Query("StandardMilestones");
    query.containedIn("babySex", [-1, babySex]);
    query.containedIn("parentSex", [-1, parentSex]);
    if(filter) query.containsAll("searchIndex", search.tokenize(filter));

    if (timePeriod == "future") {
        query.greaterThanOrEqualTo("rangeHigh", rangeDays);
        query.ascending("rangeHigh,rangeLow");
    } else if (timePeriod == "past") {
        query.lessThanOrEqualTo("rangeHigh", rangeDays);
        query.descending("rangeHigh,rangeLow");
    } else {
        response.error("Invalid query, unknown timePeriod '" + timePeriod + "'");
        return;
    }

    // Bit if a hack here, using string column here : See https://parse.com/questions/trouble-with-nested-query-using-objectid
    query.doesNotMatchKeyInQuery("objectId", "standardMilestoneId", innerQuery);
    query.limit(limit);
    query.skip(skip);
    query.select(["title", "url", "rangeHigh", "rangeLow"])
    query.find({
        success:function (results) {
            response.success(results);
        },
        error:function (error) {
            response.error(error);
        }
    });
});


