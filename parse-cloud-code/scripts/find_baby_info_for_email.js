// This is written to help debug a problem with inapproriate tips being assigned.
var Parse = require('./init_parse').createParse();
var utils = require("../cloud/utils.js");
var DEBUG = false;


var fs = require('fs');
var _ = require("underscore");
var readline = require('readline');

var rl = readline.createInterface({
    input:process.stdin,
    output:process.stdout
});

rl.question("Enter email addresses separated by commas: ", function (emailsText) {
    rl.close();

    var emails = _.uniq(emailsText.split(",").map(function(email) {
        return email.trim();
    }));

    var emailCount = emails.length;
    var userCount = 0;
    var babyCount = 0;


    var query = new Parse.Query(Parse.User);
    query.containedIn("email", emails);
    var promise = query.each(function(user) {
        userCount++;
        var email = user.get("email");




        var babyQuery = new Parse.Query("Babies");
        babyQuery.equalTo("parentUser", user);
        return babyQuery.each(function(baby) {
            var milestoneCountQuery = new Parse.Query("MilestoneAchievements");
            milestoneCountQuery.equalTo("baby", baby);
            return milestoneCountQuery.count().then(function(count) {
                emails = _.without(emails,email);
                babyCount++;
                var name = baby.get("name");
                var birthDate = baby.get("birthDate");
                console.log(email + " has baby " + name + " who is " + Math.abs(utils.dayDiffFromNow(birthDate)).toFixed(0) + " days old with " + count + " achievements");
            });
        });
    });

    promise.then(function() {
        console.log("DONE!" + emailCount + " emails input " + userCount + " users found and " + babyCount + " babies found");
        if(emails.length > 0) {
            console.warn("No babies found for emails: " + emails.join(","));
        }
    }, function(error) {
        console.error(JSON.stringify(error));
    })

});

