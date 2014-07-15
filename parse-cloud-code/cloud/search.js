var lang = "english";
var stopWords = ["the", "in", "and", "he", "she", "him", "her", "his"];
var toLowerCase = function (w) {
    return w.toLowerCase();
};
var _ = require('underscore');
var Snowball = require('cloud/node_modules/snowball/stemmer/lib/Snowball.js');

function canonicalize(words) {
    var stemmer = new Snowball(lang);
    var stem = function(w) {
        stemmer.setCurrent(w);
        stemmer.stem();
        return stemmer.getCurrent();
    };

    words = _.map(words, toLowerCase);
    words = _.map(words,stem);
    words = _.filter(words, function(w) { return w.match(/^\w+$/) && ! _.contains(stopWords, w); });
    return words;
}
module.exports.canonicalize = canonicalize;

module.exports.tokenize = function () {
    var allWords = [];
    for (var i = 0; i < arguments.length; i++) {
        var words = arguments[i].split(/\b/);
        allWords.push.apply(allWords, canonicalize(words));
    }
    return _.uniq(allWords, false);
};



