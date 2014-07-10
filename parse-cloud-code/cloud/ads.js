// Ad rotation

var isDev = Parse.applicationId === "NlJHBG0NZgFS8JP76DBjA31MBRZ7kmb7dVSQQz3U";
var host = isDev ? "dataparenting-dev" : "dataparenting";

var adPath = "http://" + host +  ".parseapp.com/ads/";
var smallAdPath = adPath + "320x50/";
var mediumAdPath = adPath + "213x320/";

var linkDomainBase = "http://dataparenting.com/";
var donateLinkPath = linkDomainBase + "donate/";
var contactLinkPath = linkDomainBase + "contact/";
var interviewLink = "http://parentsintech.com/get-interviewed/";

var smallAds = [
    {imageUrl:smallAdPath + "DataDads Ad1 Ramen Noodles.jpg", linkUrl:donateLinkPath},
    {imageUrl:smallAdPath + "DataDads Milk1.jpg", linkUrl:donateLinkPath},
    {imageUrl:smallAdPath + "DataDads Uggs1.jpg", linkUrl:donateLinkPath},
    {imageUrl:smallAdPath + "DataDads Uggs2.jpg", linkUrl:donateLinkPath},
    {imageUrl:smallAdPath + "DataDads Noodles2.jpg", linkUrl:donateLinkPath},
    {imageUrl:smallAdPath + "DataDads Improve1.jpg", linkUrl:contactLinkPath},
    {imageUrl:smallAdPath + "DataDads Ad Profile1.jpg", linkUrl:interviewLink},
    {imageUrl:smallAdPath + "DataDads New Parent1.jpg", linkUrl:interviewLink}
];

var mediumAds = [
    {imageUrl:mediumAdPath + "DataDads Milk LG1.jpg", linkUrl:donateLinkPath},
    {imageUrl:mediumAdPath + "DataDads UggsLG2.jpg", linkUrl:donateLinkPath},
    {imageUrl:mediumAdPath + "DataDads NoodlesLG1.jpg", linkUrl:donateLinkPath},
    {imageUrl:mediumAdPath + "DataDads Improve LG1.jpg", linkUrl:contactLinkPath},
    {imageUrl:mediumAdPath + "DataDads Profile LG1.jpg", linkUrl:interviewLink}
];

var adsBySize = {
        small: {size : { width :320, height: 50}, ads : smallAds },
        medium : {size : { width :213, height: 320}, ads : mediumAds}
};

Parse.Cloud.define("getAdToShow", function (request, response) {
    // TODO: Track user and rotate ads!
    var adChoices = adsBySize[request.params.size];
    if(adChoices) {
        // For now this is just random, but in the future we want to rotate these!
        var randomIdx = Math.floor(Math.random() * adChoices.ads.length);
        response.success({ size : adChoices.size, ad : adChoices.ads[randomIdx]});
    } else {
        response.error(400,"Invalid ad request");
    }
});