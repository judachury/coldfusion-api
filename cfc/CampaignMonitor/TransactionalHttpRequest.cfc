/**
* @displayname CampaignMonitorHttpRequest
* @author judachury 
* @hint https://www.campaignmonitor.com/api/
**/
component accessors="true" output="false" extends="cfc.HTTPRequest" {

	property name="apikey" getter="false" hint="property";
	property name="username" hint="property";
	property name="url" hint="property";

	CONS.LOG_NAME = 'HTTPRequest';
	CONS.USERNAME =  'secret';
	CONS.POST =  'post';
	CONS.SEND = 'send';
	CONS.HEADER = 'header';
	CONS.CONTENT_TYPE = 'Content-Type';
	CONS.APP_JSON = 'application/json';

	/**
	* @Description Component Constructor
	* @output false
	* @apikey APi Key provided by the RESTFul service
	* @url The url you wish to connect to
	* @username secret is added by default if not required
	* @logname The file name you wish to log errors - no extension as it is .log by default
	**/
	public TransactionalHttpRequest function init (
		required string apikey, 
		required string url, 
		string username = CONS.USERNAME, 
		string logname = CONS.LOG_NAME) {

		Super.init(Arguments.logname);
		setApikey(Arguments.apikey);
		setUsername(Arguments.username);
		setUrl(Arguments.url);

		return this;
	}

	/**
	* @Description Parameters for the request
	* @output false
	* @url Base url provided already in Constructor - This is the next part of the base url
	* @method POST is provided by default
	**/
	private Struct function getAttributes(string url = '', string method = 'POST') {
		var context = structNew();
		context['method'] = Arguments.method;
		context['method'] = Arguments.method;
		context['username'] = Variables.apikey;
		context['password'] = '';
		context['url'] = getUrl() & Arguments.url;
		return context;
	}

	/**
	* @Description Attributes for the request
	* @output false
	* @url Base url provided already in Constructor - This is the next part of the base url
	* @method POST is provided by default
	**/
	private Array function getParams(required struct body) {
	//Body may need to change to an array of structs to append in context, but not for now
		var context = [
			{type=CONS.HEADER, name=CONS.CONTENT_TYPE, value=CONS.APP_JSON}
		];
		arrayAppend(context, body);
	
		return context;
	}

	/**
	* @description send a Smart Transactional email
	* @output false
	* @id email id
	* @data a json string to be in the request
	**/
	public Struct function sendSmartEmail (required string id, required string data) {
		var node = Arguments.id & '/' & CONS.SEND;
		var body = structNew();
		body.type = 'body';
		body.name = '';
		body.value = data;

		Super.initiateRequest(attributes=getAttributes(node), params=getParams(body));

		return Super.sendRequest();
	}
}