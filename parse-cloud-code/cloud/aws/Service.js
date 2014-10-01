	( function(){


		var  Class 		= require( "cloud/aws/ee-class" );
		

		module.exports = new Class( {


			errors: []



			, init: function( options ){
				this.service = options.service;
				this.version = options.version;

				this.loadServiceDefinition( "generic" );
				this.loadServiceDefinition( this.service.toLowerCase() + "." + this.version.toLowerCase() );
			}




			, decode: function( strData, callback ){
				var decodedData;

				try {
					switch ( this.type ){
						case "json":
							decodedData = JSON.parse( strData );
							break;

						default:
							throw new Error( "decoder for service type <" + this.type + "> nor found!" );
					}
				} catch ( e ){
					return callback( new Error( "Failed to decode response: " + e.message ) );
				}
				callback( null, decodedData );
			}



			, getErrorDetail: function( statusCode, data ){
				var   type 		= this.getErrorType( data )
					, message 	= this.getErrorMessage( data )
					, reg, err, detail ;

				if ( this.errors[ statusCode ] ){
					if ( reg = new RegExp( this.errors[ statusCode ].__reg, "i" ).exec( type ) ){
						detail = this.errors[ statusCode ][ reg[ 1 ].toLowerCase().trim() ];
						err = new Error( message || detail.message );
						err.name = detail.signature
						err.description = detail.message;
						return err;
					}
				}

				if ( type && message ){
					err = new Error( message );
					err.name = type;
					return err;
				}

				return null;
			}



			, loadServiceDefinition: function( name ){
				try {
					var definition = require( "cloud/aws/services/" + name + '.js');

					if ( name !== "generic" ){
						if ( !definition.contentType ) throw new Error( "missing contentType attribute" );
						if ( !definition.type ) throw new Error( "missing type attribute" );
						if ( !definition.getErrorType ) throw new Error( "missing getErrorType function" );
						if ( !definition.getErrorMessage ) throw new Error( "missing getErrorMessage function" );

						this.contentType 		= definition.contentType;
						this.type 				= definition.type.toLowerCase();
						this.getErrorType 		= definition.getErrorType.bind( this );
						this.getErrorMessage 	= definition.getErrorMessage.bind( this );
					}

					if ( definition.errors ){
						var status = Object.keys( definition.errors ), s =status.length;
						while( s-- ){
							var errors = Object.keys( definition.errors[ status[ s ] ] ), e = errors.length;
							if ( !this.errors[ status[ s ] ] ) this.errors[ status[ s ] ] = {};							

							while( e-- ){
								this.errors[ status[ s ] ][ errors[ e ].toLowerCase().trim() ] = {
									signature:  errors[ e ]
									, message: 	definition.errors[ status[ s ] ][ errors[ e ] ]
								}
							}

							Object.defineProperty( this.errors[ status[ s ] ], "__reg", { 
								  value: 		"(" +  Object.keys( this.errors[ status[ s ] ] ).join( "|" ) + ")"
								, configurable: true
							} );
						}
					}
				} catch ( err ){
					console.log( err );
					throw new Error( "failed to laod service definition for " + this.service + " version " + this.version + ":" + err.message );
				}
			}
		} );










	} )();