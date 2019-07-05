/**
 * @displayname DatabaseService
 * @hint Access DB procedures
 * @output false
 * @author judachury
 */
component accessors="true" {
	
	property name="procService";
	property name="schema";

	include '/i18n/system/en-gb.cfm';

	CONS.HASH = 'SHA-512';
	
	/**
	 * @description Initiate a data service. This is the Gateway in the whole application
	 *
	 * @datasource the datasource that has been configured in your appliation
	 * @schema the shema configure in the database
	 */
	public DatabaseService function init(required string datasource, required string schema) {
		var spService = new storedProc();
        spService.setDatasource(Arguments.datasource);
		This.setSchema(Arguments.schema);
		This.setProcService(spService);

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

		Variables.procService.clearProcResults();
		Variables.procService.clearParams();
		Variables.procService.setProcedure('[' & This.getSchema() & '].[' & Arguments.procedure & ']');
	
		// Add all the required params for this procedure
		for (var i=1; i LTE ArrayLen(Arguments.formParams); i+=1) {				
			Variables.procService.addParam(cfsqltype = Arguments.formParams[i].sqltype, type= "in", value = Arguments.formParams[i].value);
		}
		
		// set all the results sets to return
		for (var i=1; i LTE Arguments.resultSet; i+=1) {
			var rs = 'rs' & i;
			Variables.procService.addProcResult(name = rs, resultset = i);
		} 
		var result = Variables.procService.execute().getProcResultSets();

		return result;
	}

}