/////////////////////////// Percentile Calculations //////////////////////
Parse.Cloud.define("percentileRanking", function (request, response) {

    if (typeof request.params.completionDays === 'undefined') {
        response.error("Invalid query, need completionDays parameter.");
        return;

    } else if (typeof request.params.milestoneId === 'undefined') {
        response.error("Invalid query, need milestoneId parameter.");
        return;
    }

    var milestoneId = request.params.milestoneId;
    var completionDays = parseInt(request.params.completionDays);

    Parse.Cloud.useMasterKey();
    // Run both queries in parralel
    var countQuery = new Parse.Query("MilestoneAchievements");
    countQuery.equalTo("standardMilestoneId", milestoneId);
    countQuery.exists("completionDays");

    var scoreQuery = new Parse.Query("MilestoneAchievements");
    scoreQuery.equalTo("standardMilestoneId", milestoneId);
    scoreQuery.exists("completionDays");
    // NOTE: A completion day greater represents a lower score.
    scoreQuery.greaterThan("completionDays", completionDays);
    Parse.Promise.when(countQuery.count(), scoreQuery.count())
            .then(function (totalCount, scoreCount) {
                console.log("Score Count=" + scoreCount + " Total Count=" + totalCount);
                // Need at least mine and one other to compare
                if (totalCount == 0) {
                    // Nothing to compare to, just say that you are ahead of 100% of babies.
                    p = 99.99;
                } else {
                    p = (scoreCount / totalCount) * 100;
                }
                response.success(p);
            }, function (error) {
                response.error(error);
            });
});
