// Ad rotation
Parse.Cloud.define("getAdToShow", function (request, response) {
    // TODO: Simply load all ads on Phone, and have phone rotate randomly
    // TODO: Also have phone refresh once daily for new ads.
    var SIZES = { small : {width : 320, height : 50 }};
    var size = SIZES[request.params.size];
    if(!size) {
        response.error(400, "Invalid size specified: " + request.params.size);
        return;
    }

    var query = new Parse.Query("Ads");
    query.equalTo("size", request.params.size);
    query.equalTo("enabled", true);
    query.count().then(function (count) {
        return Parse.Promise.as(Math.floor(Math.random() * count));
    }).then(function (randomIdx) {
                query.skip(randomIdx);
                query.limit(1);
                return query.first();
            }).then(function (result) {
                return Parse.Promise.as({
                    size:SIZES[result.get("size")],
                    ad:{
                        imageUrl:result.get("bannerImageUrl"),
                        linkUrl:result.get("clickDestinationUrl")
                    }
                });
            }).then(function(ad) {
                response.success(ad);
            },
            function (error) {
                console.error(JSON.stringify(error));
                response.error(400, "Invalid ad request");
            });
});