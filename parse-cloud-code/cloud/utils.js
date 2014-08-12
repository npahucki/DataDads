// TODO: read from localization file.
var PRONOUN_TRANSLATIONS = {
    "en" : {
        "${he}" : ["she","he"],
        "${He}" : ["She" ,"He"],
        "${his}" : ["her","his"],
        "${his:p}" : ["hers","his"],
        "${His}" :  ["Her","His"],
        "${His:p}" :  ["Hers","His"],
        "${him}" :  ["her","him"]
    }
};

function treatAsUTC(date) {
    var result = new Date(date);
    result.setMinutes(result.getMinutes() - result.getTimezoneOffset());
    return result;
}

exports.daysBetween = function(startDate, endDate) {
    var millisecondsPerDay = 24 * 60 * 60 * 1000;
    return (treatAsUTC(endDate) - treatAsUTC(startDate)) / millisecondsPerDay;
};

exports.dayDiffFromNow = function(date) {
    return exports.daysBetween(new Date(), date);
};

// Baby sex should be 1:Male or 0:Female
exports.replacePronounTokens = function(stringWithTokens, isMale, lang) {
    var result = stringWithTokens;
    var keyMap = PRONOUN_TRANSLATIONS[lang];
    if(keyMap) {
        for(var key in keyMap) {
            // TODO: Cache RegExs
            var value = keyMap[key][(isMale ? 1: 0)];
            result = result.replace(new RegExp("\\" + key), value);
        }
    }
    return result;
};

exports.isDev = function() {
    return Parse.applicationId === "NlJHBG0NZgFS8JP76DBjA31MBRZ7kmb7dVSQQz3U";
};
