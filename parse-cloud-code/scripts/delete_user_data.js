var Parse = require('parse').Parse;
var _ = require('underscore');
//Parse.initialize( appId, jsKey, master));

Parse.Cloud.useMasterKey();


var query = new Parse.Query('MilestoneAchievements');
query.containedIn("baby", [
    {__type:"Pointer", className:"Babies", objectId:"pqKyFL9YT7"}
]);
query.each(function (milestone) {
    ids.push(milestone.id);
}).then(function () {
    data.results = _.filter(mateoObjects, function(mateoMilestone) {
        return !_.contains(ids,mateoMilestone.objectId);
    });
    console.log("Mateo Missing Count:" + data.results.length);
    fs.writeFile("/Users/npahucki/Downloads/MateoMilestones.json", JSON.stringify(data.results), function (err) {
        if (err) {
            console.log(err);
        } else {
            console.log("The file was saved!");
        }
    });
});







