/**
 * Google ReCaptcha 
 * 	 https://developers.google.com/recaptcha/docs/start
 */
component accessors='true' {
	
	property apiUrl;
	property apiKey;
	property service;
	property response;
	
	VARIABLE.POST = 'POST';
	VARIABLE.FORM_FIELD = 'formField';
	
	VARIABLE.CODE_200 = '200';

	public void function init(required string apiUrl, required string keyId) {
		var	response = {};

		response['successful'] = false;
		response['servercode'] = '';
		response['content'] = '';

		setResponse(response);
		setApiUrl(apiUrl);
		setApiKey(keyId);

		resetOrCreateHttp(true, '', VARIABLE.POST);
	}
	
	private void function resetOrCreateHttp(boolean newService = false, string url = '', string method = VARIABLE.POST, string userResponse = '') {
		//ColdFusion will not allow this request unless the values are reset
		if (newService) {
			var httpService = new http();

			httpService.setMethod(method);
		} else {
			var httpService = getService();
			
			httpService.clearAttributes();
			httpService.clearParams();

			httpService.setMethod(method);		
			httpService.setUrl(url);

			httpService.addParam(type=VARIABLE.FORM_FIELD, name='secret', value=apiKey); 
			httpService.addParam(type=VARIABLE.FORM_FIELD, name='response', value=userResponse); 
		}
		
		setService(httpService);
	}
	
	private void function resetResponse() {
		response['servercode'] = '';
		response['content'] = '';
		response['successful'] = false;
	}
	
	private void function makeRequest(required string url, string userResponse = '') {

		resetResponse();

		try {

			resetOrCreateHttp(false, url, VARIABLE.POST, userResponse);
			
			var context = service.send().getPrefix();

			response['servercode'] = context.responseHeader.status_code;

			if (response['servercode'] EQ VARIABLE.CODE_200) {
				response['content'] = context.filecontent;
				response['successful'] = true;
			}
			
		} catch (any ex) {
			response['exception'] = ex;
		}
	}
	
	public struct function verify(required string userResponse) {

		makeRequest(apiUrl, userResponse);
		
		return getResponse();
	}
	
	

}