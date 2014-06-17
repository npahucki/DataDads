module.exports.normalize = function() {
    var args = Array.prototype.slice.call(arguments);
    allText = args.join(' ');
    return allText.toLowerCase();
};
