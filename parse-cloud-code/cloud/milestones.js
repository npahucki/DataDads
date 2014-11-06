var search = require("cloud/search.js");

Parse.Cloud.define("queryMyMilestones", function (request, response) {

    if (typeof request.params.babyId == "undefined" || typeof request.params.rangeDays == "undefined") {
        response.error("Invalid query, need babyId and rangeDays parameters.");
        return;
    }

    var babyId = request.params.babyId;
    var babySex = request.params.babyIsMale ? 1 : 0;
    var parentSex = request.params.parentIsMale ? 1 : 0;
    var timePeriod = request.params.timePeriod;
    var rangeDays = parseInt(request.params.rangeDays);
    var limit = parseInt(request.params.limit);
    var skip = parseInt(request.params.skip);
    var filterTokens = request.params.filterTokens;
    var showPostponed = request.params.showPostponed;
    var showIgnored = request.params.showIgnored;

    innerQuery = new Parse.Query("MilestoneAchievements");
    innerQuery.equalTo("baby", {__type:"Pointer", className:"Babies", objectId:babyId});
    innerQuery.exists("standardMilestoneId");
    innerQuery.select(["standardMilestoneId"]);
    if (showPostponed) innerQuery.equalTo("isPostponed", false);
    if (showIgnored) innerQuery.equalTo("isSkipped", false);
    innerQuery.limit(1000); // NOTE: if we start getting over 1000 achievements, this is not going to work!!!

    query = new Parse.Query("StandardMilestones");
    query.containedIn("babySex", [-1, babySex]);
    query.containedIn("parentSex", [-1, parentSex]);
    if (filterTokens) {
        filterTokens = search.canonicalize(filterTokens);
        query.containsAll("searchIndex", filterTokens);
    }

    if (timePeriod == "future") {
        query.greaterThanOrEqualTo("rangeHigh", rangeDays);
        query.ascending("rangeHigh,rangeLow");
    } else if (timePeriod == "past") {
        query.lessThan("rangeHigh", rangeDays);
        query.descending("rangeHigh,rangeLow");
    } else {
        response.error("Invalid query, unknown timePeriod '" + timePeriod + "'");
        return;
    }

    // Bit if a hack here, using string column here : See https://parse.com/questions/trouble-with-nested-query-using-objectid
    query.doesNotMatchKeyInQuery("objectId", "standardMilestoneId", innerQuery);

    var countPromise = query.count();
    query.limit(limit);
    query.skip(skip);
    query.select(["title", "url", "rangeHigh", "rangeLow", "canCompare", "enteredBy"]);
    var findPromise = query.find();

    Parse.Promise.when(countPromise, findPromise).
            then(function (count, queryResults) {
                response.success({"count":count, "milestones":queryResults});
            }, function (error) {
                response.error(error);
            });

});


Parse.Cloud.beforeSave("StandardMilestones", function (request, response) {
    var milestone = request.object;
    if (!milestone.get("searchIndex") || (milestone.dirty("title") && milestone.previous("title") != milestone.get("title"))) {
        if (milestone.get("title")) { // During population, the title may have been blank
            var tokens = search.tokenize(milestone.get("title"));
            milestone.set("searchIndex", tokens);
        }
    }
    response.success();
});


