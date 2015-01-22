// This should be used just once in production after 1.3 is deployed, then it should be deleted!

var now = new Date();
var Parse = require('./init_parse').createParse();
var util = require("../cloud/utils");

var count = 0;
var query = new Parse.Query("BabyAssignedTips");
query.doesNotExist("viewedOn");
console.log("Finding objects to update...");
query.each(function (assignment) {
    assignment.set("viewedOn",now);
    return assignment.save().then(function() {
        count++;
        console.log("Saved " + count + " objects...");
    });
}).then(function () {
    console.log("DONE! Updated " + count + " records");
}, function (error) {
   console.error("Crap! " + JSON.stringify(error));
});

