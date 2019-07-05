/**
 * @displayname DatabaseServiceTokenized
 * @hint Access DB procedures with tokens
 * @output true
 * @author judachury
 */
component accessors="true" extends="cfc.Database.DatabaseService" {
	
	property name="sharedSecret" getter="false";

	include '/i18n/system/en-gb.cfm';

	CONS.HASH = 'SHA-512';
	
	/**
	 * @description Initiate a data service. This is the Gateway in the whole application
	 *
	 * @datasource the datasource that has been configured in your appliation
	 * @schema the shema configure in the database
	 */
	public DatabaseServiceTokenized function init(required string datasource, required string schema) {
		var spService = new storedProc();
        spService.setDatasource(Arguments.datasource);
		Super.setSchema(Arguments.schema);
		Super.setProcService(spService);
		Variables.fetchSharedSecret();

		return This;
	}
	
	/**
	 * @description Make a call to the database
	 * @hint resultSet must always return from the db, otherwise, this can cause errors
	 * @procedure The name of the procedure to call
	 * @formParams The values to send
	 * @resultSet the number of resultsets required to return
	 */
	public struct function call(required string procedure, required array formParams = [], numeric resultSet = 1) {
		var rsp = Super.call(arguments.procedure, arguments.formParams, arguments.resultSet);
		//Checks the validity of the token and returns the query back
		return variables.validateResponse(rsp, procedure);
	}

	/**
	 * @description optain the token to add as parameter in the call for your db request
	 * @hint The input in token needs will always be trim and in lower case
	 * @output false
	 */
	public string function getToken(required input) {
		var pretoken = lcase(trim(arguments.input)) & '.' & variables.sharedSecret;
		return Hash(pretoken, CONS.HASH);
	}

	/**
	 * @description optain the token in JSON to add as parameter in the call for your db request
	 * @output false
	 * @input The value that goes with sharedsecred
	 * @prop The prop return with token
	 */
	public string function getTokenJSON(required string input, string prop = 'ts') {
		var rsp = StructNew('ordered');
		rsp[arguments.prop] = arguments.input;
		rsp['token'] = This.getToken(arguments.input);
		return serializeJSON(rsp);
	}

	/**
	 * @description validate a token return from db
	 * @output true
	 */
	public boolean function validateToken(required ts, required token) {
		var exToken = This.getToken(arguments.ts);
		return (exToken EQ token);
	}

	private function validateResponse(resultsets) {
		var temp = deserializeJSON( arguments.resultsets.rs1.json );
		if (NOT This.validateToken(temp.ts, temp.token)) {
			temp.status = 0;
			temp.errorCode = '-444';
			temp.message = resource.error[temp.errorCode];

			arguments.resultsets.rs1 = queryNew('json', 'varchar', [
				serializeJSON(temp)
			]);
		} 
		return arguments.resultsets;
	}

	/**
	 * 
	 * @description Generate a shared secret
	 * @hint Called within controller
	 * @output true
	 */
	private void function fetchSharedSecret() {
		try {
			var rsp = DeserializeJSON(Super.call('getSharedSecret').rs1.json);

			if (rsp.status) {
				variables.sharedSecret = rsp.data.sharedSecret;
			} else {
				throw(message='Error code: #rsp.errorCode# | Message: #rsp.message#', type='SharedSecretException');	
			}
		} catch (any ex) {
			throw(message=resource.exceptions.SharedSecret, type='SharedSecretException');
		}
	}

}