// This is written to help debug a problem with inapproriate tips being assigned.
var Parse = require('./init_parse').createParse();
var utils = require("../cloud/utils.js");
var DEBUG = false;

    var query = new Parse.Query("BabyAssignedTips");
    query.include("baby");
    query.include("tip");
    query.each(function(assignment) {
        var tip = assignment.get("tip");
        var baby = assignment.get("baby");
        if(!baby) {
            console.warn("Assignemnt " + assignment.id +" has no baby!");
            return assignment.destroy();
        } else if(!tip) {
            console.warn("Assignemnt " + assignment.id +" has no tip!");
            return assignment.destroy();
        }

        var rangeHigh = tip.get("rangeHigh");
        var rangeLow = tip.get("rangeLow");
        var babyDaysOldAtTipDelivery = utils.daysBetween(baby.get("dueDate"),assignment.createdAt);
        if(rangeLow > babyDaysOldAtTipDelivery || rangeHigh < babyDaysOldAtTipDelivery) {
            console.warn("Deleting bad tip assignment " + assignment.id + " for baby " + baby.id + "("+rangeLow + "-" + rangeHigh +"):" + babyDaysOldAtTipDelivery + " assigned on " + assignment.createdAt);
            return assignment.destroy();
        }
    });

