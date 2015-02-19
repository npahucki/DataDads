// Ad rotation
Parse.Cloud.define("getAdToShow", function (request, response) {
    // TODO: Simply load all ads on Phone, and have phone rotate randomly
    // TODO: Also have phone refresh once daily for new ads.

    var width = request.params.screenWidth || 320; // default
    var appVersion = request.params.appVersion;

    var query = new Parse.Query("Ads");
    query.equalTo("width", width);
    if(appVersion <= "1.3.1") {
        // In versions earlier than 1.3.1, the Ad height was fixed at 50
        // So we can only use these Ads, not the new ones.
        query.equalTo("height", 50);
    } else {
        query.equalTo("deprecated", false);
    }


    // NOTES: For a width of 320, new ads will have a height of 70 - matching what simon did.
    // In photo shop, size images to 375 and 414 - try to keep aspect ratio.

    query.equalTo("enabled", true);
    query.count().then(function (count) {
        return Parse.Promise.as(Math.floor(Math.random() * count));
    }).then(function (randomIdx) {
                query.skip(randomIdx);
                query.limit(1);
                return query.first();
            }).then(function (result) {
                if(result) {
                    return Parse.Promise.as({
                        size:{width : width, height : result.get("height")},
                        ad:{
                            imageUrl:result.get("bannerImageUrl"),
                            linkUrl:result.get("clickDestinationUrl")
                        }
                    });
                } else {
                    return Parse.Promise.error("No Ads Found");
                }
            }).then(function(ad) {
                response.success(ad);
            },
            function (error) {
                console.error(JSON.stringify(error));
                response.error(400, "Invalid ad request");
            });
});