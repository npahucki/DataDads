// Ad rotation

var isDev = Parse.applicationId === "NlJHBG0NZgFS8JP76DBjA31MBRZ7kmb7dVSQQz3U";
var host = isDev ? "dataparenting-dev" : "dataparenting";

var adPath = "http://" + host +  ".parseapp.com/ads/";
var smallAdPostFix = "640x100";
var dpBaseUrl = "http://dataparenting.com/";
var categories = [
    {name : "contact", count: 1, url : dpBaseUrl + "contact/?utm_source=app&utm_medium=app-small&utm_campaign=dp-contact"},
    {name : "donate", count : 2, url: dpBaseUrl + "donate/?utm_source=app&utm_medium=app-small&utm_campaign=dp-donate"},
    {name : "parents", count : 2, url : "http://parentsintech.com/get-interviewed/?utm_source=app&utm_medium=app-small&utm_campaign=PIT_Profile"}
];

var smallAds = [];
for(i=0; i<categories.length; i++) {
    var category = categories[i];
    for(ii=0; ii < category.count; ii++) {
        var imageName = category.name + "-" + smallAdPostFix + "-" + (ii+1) + ".jpg";
        smallAds.push({
            imageUrl : adPath + imageName ,
            linkUrl : category.url + "&utm_content=" + imageName }
        );
    }
}

var adsBySize = {
        small: { size : { width :320, height: 50}, ads : smallAds }
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