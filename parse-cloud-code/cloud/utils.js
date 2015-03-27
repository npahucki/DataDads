var moment = require('moment');

// TODO: read from localization file.
var PRONOUN_TRANSLATIONS = {
    "en":{
        "${he}":["she", "he"],
        "${He}":["She" , "He"],
        "${his}":["her", "his"],
        "${his:p}":["hers", "his"],
        "${His}":["Her", "His"],
        "${His:p}":["Hers", "His"],
        "${him}":["her", "him"]
    }
};

var MILLIS_PER_DAY = 24 * 60 * 60 * 1000;



function treatAsUTC(date) {
    var result = new Date(date);
    result.setMinutes(result.getMinutes() - result.getTimezoneOffset());
    return result;
}

function pluralizeUnits(amount, unit){
    if(amount == 1){
        return "1 " + unit;
    }
    else{
        return amount + " " + unit + "s";
    }
}

exports.oneLinkFollowUrl = "http://m.onelink.me/d6d1120e";


exports.isDev = function () {
    return  typeof Parse == "undefined" ? true : Parse.applicationId === "NlJHBG0NZgFS8JP76DBjA31MBRZ7kmb7dVSQQz3U";
};

exports.websiteHost = exports.isDev() ? "dataparenting-dev.parseapp.com" : "view.dataparenting.com";

exports.dateAddDays = function (date, days) {
    return new Date(date.getTime() + (MILLIS_PER_DAY * days));
};

exports.daysBetween = function (startDate, endDate) {
    return Math.round( (treatAsUTC(endDate) - treatAsUTC(startDate)) / MILLIS_PER_DAY );
};

exports.dayDiffFromNow = function (date) {
    return exports.daysBetween(new Date(), date);
};

exports.deltaToPeriod = function (first, second) {
    var delta = moment(second).diff(first, 'days');
    return moment.duration(delta, 'days').humanize();
};

exports.daysToPeriod = function (days) {
    switch(true){
        case (days == 0):
            return "newborn";
            break;
        case (days < 30):
            return pluralizeUnits(days, "day");
            break;
        case (days == 30):
            return "a month";
            break;
        case (days < 60):
            var days_mod = days % 30;
            return "1 month and " + pluralizeUnits(days_mod, "day");
            break;
        case (days == 60):
            return "2 months";
            break;
        case (days < 90):
            var days_mod = days % 60;
            return "2 months and " + pluralizeUnits(days_mod, "day");
            break;
        case (days < 365):
            var months = parseInt(days / 30);
            var weeks = parseInt( (days % 30) / 7 );
            var ret = "";
            if (weeks == 4){
                months++;
                weeks = 0;
            }
            if (weeks == 0){
                if (months == 12){
                    ret =  pluralizeUnits(1, "year")
                }
                else{
                    ret =  months + " months";
                }
            }
            else{
                ret = months + " months and " + pluralizeUnits(weeks, "week");
            }
            return ret;
            break;
        default:
            var ret = "";
            var years = parseInt(days / 365);
            var months = parseInt( (days % 365) / 30);
            if (months == 12){
                years++;
                months = 0;
            }
            if (months == 0){
                ret = pluralizeUnits(years, "year");
            }
            else{
                ret = pluralizeUnits(years, "year") + " and " + pluralizeUnits(months, "month");
            }
            return ret;
            break;
    }


};

exports.dateToHuman = function (date) {
    return moment(date).format("Do of MMM YYYY");
};

exports.achievementViewerUrl = function (achievement) {
    return "http://" + exports.websiteHost + "/achievements/" + achievement.id
};

exports.inviteAcceptUrl = function (followConnectionInvite) {
    return "http://" + exports.websiteHost + "/accept_invite/" + followConnectionInvite.id
};


// Baby sex should be 1:Male or 0:Female
exports.replacePronounTokens = function (stringWithTokens, isMale, lang) {
    var result = stringWithTokens;
    var keyMap = PRONOUN_TRANSLATIONS[lang];
    if (keyMap) {
        for (var key in keyMap) {
            // TODO: Cache RegExs
            var value = keyMap[key][(isMale ? 1 : 0)];
            result = result.replace(new RegExp("\\" + key), value);
        }
    }
    return result;
};

exports.awsVideoEnv = function() {
    var info = {};
    if(exports.isDev()) {
        info.bucket = "dp-mf-media-dev";
        info.accessKey = "AKIAJRGMQXTMWZAS63EQ";
        info.secretKey = "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";
        info.webVideoPipelineId = "1412173550726-nz7h9a";
    } else {
        info.bucket = "dp-mf-media-prod";
        info.accessKey = "AKIAJVJAO4WVS4INUGUA";
        info.secretKey = "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";
        info.webVideoPipelineId = "1412984874675-8ajzup";
    }
    return info;
}


var Base64 = {


    _keyStr:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",


    encode:function (input) {
        var output = "";
        var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
        var i = 0;

        input = Base64._utf8_encode(input);

        while (i < input.length) {

            chr1 = input.charCodeAt(i++);
            chr2 = input.charCodeAt(i++);
            chr3 = input.charCodeAt(i++);

            enc1 = chr1 >> 2;
            enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
            enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
            enc4 = chr3 & 63;

            if (isNaN(chr2)) {
                enc3 = enc4 = 64;
            } else if (isNaN(chr3)) {
                enc4 = 64;
            }

            output = output + this._keyStr.charAt(enc1) + this._keyStr.charAt(enc2) + this._keyStr.charAt(enc3) + this._keyStr.charAt(enc4);

        }

        return output;
    },


    decode:function (input) {
        var output = "";
        var chr1, chr2, chr3;
        var enc1, enc2, enc3, enc4;
        var i = 0;

        input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");

        while (i < input.length) {

            enc1 = this._keyStr.indexOf(input.charAt(i++));
            enc2 = this._keyStr.indexOf(input.charAt(i++));
            enc3 = this._keyStr.indexOf(input.charAt(i++));
            enc4 = this._keyStr.indexOf(input.charAt(i++));

            chr1 = (enc1 << 2) | (enc2 >> 4);
            chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
            chr3 = ((enc3 & 3) << 6) | enc4;

            output = output + String.fromCharCode(chr1);

            if (enc3 != 64) {
                output = output + String.fromCharCode(chr2);
            }
            if (enc4 != 64) {
                output = output + String.fromCharCode(chr3);
            }

        }

        output = Base64._utf8_decode(output);

        return output;

    },

    _utf8_encode:function (string) {
        string = string.replace(/\r\n/g, "\n");
        var utftext = "";

        for (var n = 0; n < string.length; n++) {

            var c = string.charCodeAt(n);

            if (c < 128) {
                utftext += String.fromCharCode(c);
            }
            else if ((c > 127) && (c < 2048)) {
                utftext += String.fromCharCode((c >> 6) | 192);
                utftext += String.fromCharCode((c & 63) | 128);
            }
            else {
                utftext += String.fromCharCode((c >> 12) | 224);
                utftext += String.fromCharCode(((c >> 6) & 63) | 128);
                utftext += String.fromCharCode((c & 63) | 128);
            }

        }

        return utftext;
    },

    _utf8_decode:function (utftext) {
        var string = "";
        var i = 0;
        var c = c1 = c2 = 0;

        while (i < utftext.length) {

            c = utftext.charCodeAt(i);

            if (c < 128) {
                string += String.fromCharCode(c);
                i++;
            }
            else if ((c > 191) && (c < 224)) {
                c2 = utftext.charCodeAt(i + 1);
                string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
                i += 2;
            }
            else {
                c2 = utftext.charCodeAt(i + 1);
                c3 = utftext.charCodeAt(i + 2);
                string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
                i += 3;
            }

        }

        return string;
    }

};

exports.Base64 = Base64;
exports.isValidEmailAddress = function(email) {
    var re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(email);
};


