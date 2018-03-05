/*
 * common.js: Common utility functions for requesting against Loggly APIs
 *
 * (C) 2010 Charlie Robbins
 * MIT LICENSE
 *
 */

var https = require("https"),
    util = require("util"),
    request = require("request"),
    loggly = require("../loggly")

var common = exports

//
// Failure HTTP Response codes based
// off Loggly specification.
//
var failCodes = (common.failCodes = {
    400: "Bad Request",
    401: "Unauthorized",
    403: "Forbidden",
    404: "Not Found",
    409: "Conflict / Duplicate",
    410: "Gone",
    500: "Internal Server Error",
    501: "Not Implemented",
    503: "Throttled"
})

//
// Success HTTP Response codes based
// off Loggly specification.
//
var successCodes = (common.successCodes = {
    200: "OK",
    201: "Created",
    202: "Accepted",
    203: "Non-authoritative information",
    204: "Deleted"
})

//
// Core method that actually sends requests to Loggly.
// This method is designed to be flexible w.r.t. arguments
// and continuation passing given the wide range of different
// requests required to fully implement the Loggly API.
//
// Continuations:
//   1. 'callback': The callback passed into every node-loggly method
//   2. 'success':  A callback that will only be called on successful requests.
//                  This is used throughout node-loggly to conditionally
//                  do post-request processing such as JSON parsing.
//
// Possible Arguments (1 & 2 are equivalent):
//   1. common.loggly('some-fully-qualified-url', auth, callback, success)
//   2. common.loggly('GET', 'some-fully-qualified-url', auth, callback, success)
//   3. common.loggly('DELETE', 'some-fully-qualified-url', auth, callback, success)
//   4. common.loggly({ method: 'POST', uri: 'some-url', body: { some: 'body'} }, callback, success)
//
common.loggly = function() {
    var args = Array.prototype.slice.call(arguments),
        success = args.pop(),
        callback = args.pop(),
        responded,
        requestBody,
        headers,
        method,
        auth,
        proxy,
        uri

    method = args[0].method || "GET"
    uri = args[0].uri
    requestBody = args[0].body
    auth = args[0].auth
    headers = args[0].headers
    proxy = args[0].proxy

    function onError(err) {
        if (!responded) {
            responded = true
            if (callback) {
                callback(err)
            }
        }
    }

    var requestOptions = {
        uri: uri,
        method: method,
        headers: headers || {},
        proxy: proxy
    }

    if (auth) {
        requestOptions.headers.authorization = "Basic " + new Buffer(auth.username + ":" + auth.password).toString("base64")
    }

    if (requestBody) {
        requestOptions.body = requestBody
    }

    try {
        request(requestOptions, function(err, res, body) {
            if (err) {
                return onError(err)
            }

            var statusCode = res.statusCode.toString()
            if (Object.keys(failCodes).indexOf(statusCode) !== -1) {
                return onError(new Error("Loggly Error (" + statusCode + "): " + failCodes[statusCode]))
            }

            success(res, body)
        })
    } catch (ex) {
        onError(ex)
    }
}
