(function () {
      global.Parse = require("parse-cloud-debugger").Parse;
      global.
      Parse.initialize( "NlJHBG0NZgFS8JP76DBjA31MBRZ7kmb7dVSQQz3U", "Km9C7vBKrLdnDf8Uc3Zgf3qdw3qmbYa13R8RD1q2", "ScHR4mshg3TICZKsbPiLmCFLEidiChAwLpWHIUCO");
})
();

var runOnParse = false;
var originalParseFunction = Parse._request;

Parse._request = function (options) {
    Parse.serverURL = "https://api.parse.com";

    if (runOnParse === false && options.route == "functions") {
        Parse.serverURL = "http://localhost:5555";
    }

    return originalParseFunction(options);
};

var originalRequire = require;
require = function(lib) {
    return originalRequire(lib);
};

require("../cloud/app.js");