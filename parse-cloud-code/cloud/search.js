var stopWords = ["the", "in", "and", "he", "she","him","her","his"];
var toLowerCase = function(w) { return w.toLowerCase(); };
var _ = require('underscore');

module.exports.tokenize = function() {
    var allWords = [];
    for(var i=0; i<arguments.length; i++) {
        var words = arguments[i].split(/\b/);
        words = _.map(words, toLowerCase);
        words = _.filter(words, function(w) { return w.match(/^\w+$/) && ! _.contains(stopWords, w); });
        allWords.push.apply(allWords, words);
    }

    return allWords;
};
