/**
* @displayname HTTP Request
* @hint Parent component to use on HTTP Request
* @author judachury
**/
component accessors="true" output="false" {

	property name="service";
	property name="response" ;
	property name="logname";

	//Constance are mantain in capitals
	Variables.LOG_NAME = "HTTPRequest";
	Variables.FATAL_ERROR = "fatal";
	Variables.CODE_200 = "200";

	/**
	* @Description Component Constructor
	* @logname The file name you wish to log errors - no extension as it is .log by default
	* @output false
	**/
	public HTTPRequest function init (string logname = Variables.LOG_NAME) {

		setLogname(Arguments.logname);

		//Create a new http instance only once. It saves on memory
		var httpService = new http();
		setService(httpService);
		resetResponse();

		return this;
	}


	/**
	* @description empty the struct to have default values
	* @hint utility function
	* @output false
	**/
	private void function resetResponse() {
		//If transform to JSON, access properties in lowercase
		var response = {
			'servercode': '',
			'content': '',
			'success': false
		};
		setResponse(response);
	}

	/**
	* @description empty the struct to have default values
	* @hint utility function
	* @output false
	**/
	private void function setResponseValue(required string key, any value = '') {
		Variables.properties.response[key] = value;
	}

	/**
	* @description Log errors and throw excemption to the developer
	* @hint utility function
	* @ex the Exception received
	* @output false
	**/
	private void function logError(any ex) {
		This.response['exception'] = ex;
		writeLog(type=Variables.FATAL_ERROR, application='yes', file=getLogname(), text="[#ex.type#] #ex.message#");
		/*
		Increases loding time, but the idea is that this will only happen durign Development and it will be very rare in Production
		*/
		throw(type="Bad HTTP Request", message=ex.message);
	}

	/**
	* @description Prepare http request 
	* @hint If anything goes wrong, it is likely that your are adding the wrong attributes and params for your specific request
	* @attributes add value pair of attributes. E.g: {method:'POST'}
	* @params an array of struct with the parametes you wish to add in the request. Send each struct with type (check CF docs for this), name and value.
	* @output false
	**/
	private void function initiateRequest(struct attributes = {}, array params = []) {
		try {
			resetResponse();
			
			var httpService = getService();
			//reset the request every new request
			httpService.clear();
			invoke(httpservice, 'setAttributes', Arguments.attributes);
	
			for (param in Arguments.params) {
				httpService.addParam(type=param.type, name=param.name, value=param.value);
			}
			setService(httpService);
		} catch (any ex) {
			logError(ex);
		}	
	}

	/**
	* @description Send the request
	* @hint Call initiateRequest first
	* @output false
	**/
	private Struct function sendRequest() {
		var response = getResponse();
		try {

			var httpRequest = getService().send().getPrefix();

			//Add the connection response
			response.servercode = httpRequest.responseHeader.status_code;
			/*
				Response.successful will be true always when there is a response in the http request.
				Even if the response is negative
			*/			
			response.content = httpRequest.filecontent;
			response.success = true;
	
		} catch (any ex) {
			logError(ex);
		}

		return response;
	}

}