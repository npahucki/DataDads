
	module.exports = {
		  contentType:  	"application/x-amz-json-1.0"
		, type: 			"json"
		, getErrorType: 	function( d ){ return d && d.__type ? d.__type : ""; }
		, getErrorMessage: 	function( d ){
			if ( d ) {
				if ( d.message ) return d.message;
				if ( d.Message ) return d.Message;
			}
			return "";
		}
		, errors: {
			  400: {
			  	  ResourceNotFound:					"The operation tried to access a nonexistent table or index. The resource may not be specified correctly, or its status may not be ACTIVE."
				, UnknownOperation: 				"The operation requested is unknown."
				, LimitExceeded: 					"The number of concurrent table requests (cumulative number of tables in the CREATING, DELETING or UPDATING state) exceeds the maximum allowed of 10."
				, ResourceInUse: 					"The operation conflicts with the resource's availability. For example, you attempted to recreate an existing table, or tried to delete a table currently in the CREATING state."
				, Validation: 						"The command validation failed."
				, ConditionalCheckFailed: 			"A condition specified in the operation could not be evaluated."
				, ItemCollectionSizeLimitExceeded: 	"An item collection is too large. This exception is only returned for tables that have one or more local secondary indexes."
				, ProvisionedThroughputExceeded: 	"The request rate is too high, or the request is too large, for the available throughput to accommodate."
				, Serialization: 					"Probably a type error"
			}
			, 403: {}
			, 404: {}
			, 500: {
				  InternalServerError: 				"An error occurred on the server side."
			}
			, 503: {}
		}
	};