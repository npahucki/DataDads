var Parse = require('./init_parse').createParse();
var util = require("../cloud/utils");
console.log("Reporting User/Baby anomalies");
var query = new Parse.Query(Parse.User);
var userCount = 0;
var anomalyCount = 0;

query.each(function (user) {
    userCount++;
    var babyQuery = new Parse.Query("Babies");
    babyQuery.equalTo("parentUser", user);
    return babyQuery.count().then(function(count) {
        if(count != 1) {
            anomalyCount++;
            if(user.get("email")) {
                console.error("User " + user.id + "<" + user.get("email") + "> has " + count + " babies. Created " + user.createdAt);
            }
        }
    });
}).then(function () {
    console.log("DONE! Tested " + userCount + " users and found " + anomalyCount + " problems. " +
            ((anomalyCount/userCount) * 100) + "% of users have problems.")
}, function (error) {
   console.error("Crap! " + JSON.stringify(error));
});
