


	module.exports = {
		errors: {
			  400: {
			  	  IncompleteSignature: 			"The request signature does not conform to AWS standards."
			  	, InvalidAction: 				"The action or operation requested is invalid. Verify that the action is typed correctly."
			  	, InvalidParameterCombination: 	"Parameters that must not be used together were used together."
			  	, InvalidParameterValue: 		"An invalid or out-of-range value was supplied for the input parameter."
			  	, InvalidQueryParameter: 		"AWS query string is malformed, does not adhere to AWS standards."
			  	, MissingAction: 				"The request is missing an action or a required parameter."
			  	, MissingParameter: 			"A required parameter for the specified action is not supplied."
			  	, RequestExpired: 				"The request reached the service more than 15 minutes after the date stamp on the request or more than 15 minutes after the request expiration date (such as for pre-signed URLs), or the date stamp on the request is more than 15 minutes in the future."
				, Throttling: 					"Request was denied due to request throttling."
			}
			, 403: {
				  InvalidClientTokenId: 		"The X.509 certificate or AWS access key ID provided does not exist in our records."
				, MissingAuthenticationToken: 	"Request must contain either a valid (registered) AWS access key ID or X.509 certificate."
				, OptInRequired: 				"The AWS access key ID needs a subscription for the service."
			}
			, 404: {			
			  	  MalformedQueryString: 		"The query string contains a syntax error."
			}
			, 500: {
				  InternalFailure: 				"The request processing has failed because of an unknown error, exception or failure."
			}
			, 503: {
				  ServiceUnavailable: 			"The request has failed due to a temporary failure of the server."
			}
		}
	};