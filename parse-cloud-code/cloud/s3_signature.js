var join = require('path').join;
var crypto = require('crypto'); // hosted on parse

exports.urlSigner = function (key, secret, options) {
    options = options || {};
    var endpoint = options.host || 's3.amazonaws.com';
    var port = options.port || '80';
    var protocol = options.protocol || 'http';
    var subdomain = options.useSubdomain === true;

    var hmacSha1 = function (message) {
        return crypto.createHmac('sha1', secret)
                .update(message)
                .digest('base64');
    };

    var url = function (fname, bucket) {
        if (subdomain) {
            return protocol + '://' + bucket + "." + endpoint + (port != 80 ? ':' + port : '') + (fname[0] === '/' ? '' : '/') + fname;
        } else {
            return protocol + '://' + endpoint + (port != 80 ? ':' + port : '') + '/' + bucket + (fname[0] === '/' ? '' : '/') + fname;
        }
    };

    return {
        getUrl:function (verb, bucket, fileName, contentType, expiresInMinutes) {
            var expires = new Date();
            expires.setMinutes(expires.getMinutes() + expiresInMinutes);
            var epo = Math.floor(expires.getTime() / 1000);

            var str = verb + '\n\n';
            str += (contentType ? contentType : "") + '\n';
            str += epo + '\n' + '/' + bucket + (fileName[0] === '/' ? '' : '/') + fileName;

            var hashed = hmacSha1(str);

            return url(fileName, bucket) +
                    '?Expires=' + epo +
                    '&AWSAccessKeyId=' + key +
                    '&Signature=' + encodeURIComponent(hashed);

        }

    };

};
