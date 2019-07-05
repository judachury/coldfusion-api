/**
* @displayname RealexHttpRequest
* @author judachury 
* @hint https://developer.realexpayments.com/
**/
component accessors="true" output="true" extends="cfc.HTTPRequest" {

    property name="password" getter="false" hint="property";
    property name="merchantId" getter="false" hint="property";
	property name="username" hint="property";
    property name="url" hint="property";

	CONS.LOG_NAME = 'HTTPRequest';
	CONS.USERNAME =  'secret';
	CONS.POST =  'post';
	CONS.SEND = 'send';
	CONS.HEADER = 'header';
	CONS.CONTENT_TYPE = 'Content-Type';
	CONS.APP_JSON = 'application/json';
	CONS.TEXT_XML = 'text/xml';

	/**
	* @Description Component Constructor
	* @output false
	* @url The url you wish to connect to
    * @secret REtailer password to make the connection
    * @merchantId MerchantId given by realex
	* @username secret is added by default if not required
	* @logname The file name you wish to log errors - no extension as it is .log by default
	**/
	public RealexHttpRequest function init (
        required string url, 
        required string password,
        required string merchantId,
		string username = CONS.USERNAME, 
		string logname = CONS.LOG_NAME) {

		Super.init(Arguments.logname);
        setPassword(Arguments.password);
        setMerchantId(Arguments.merchantId);
        setUsername(Arguments.username);
		setUrl(Arguments.url);

		return this;
	}

	/**
	* @Description Attributes for the request
	* @output false
	**/
	private Struct function getAttributes() {
		var context = structNew();
		context['method'] = CONS.POST;
		context['password'] = '';
		context['url'] = getUrl();
		return context;
	}

	/**
	 * @Description Parmeters for the request: header and body
	 * @output false
	 * 
	 * @body Struct with props: type, name and value=xml for the request
	 */
	private Array function getParams(required struct body) {
	//Body may need to change to an array of structs to append in context, but not for now
		var context = [
			{type=CONS.HEADER, name=CONS.CONTENT_TYPE, value=CONS.TEXT_XML}
		];
		arrayAppend(context, body);
	
		return context;
	}

	/**
	 * @description Make a request to Realex
	 * @hint https://developer.realexpayments.com/#!/api
	 * @output true
	 * 
	 * @type the type of request: verifyenrolled or verysign
	 * @order The order: key:values as required in the request, not required on verysign
	 */
	public function verifyRequest(required string type, struct order = {}) {
        var body = {
            'type': 'body',
            'name': '',
            'value': ''
		};
		var rqsData = structNew();
		var rsp = StructNew();
		if (Arguments.type EQ 'verysign') {
			Arguments.order = Variables.verify3dsResponse();
			//move obj values to a newone without card number
			for (key in Arguments.order) {
				if (key NEQ 'card') {
					rqsData[key] = Arguments.order[key];
				}
			}
			rqsData.card.number = '';
		} else {
			rqsData = Arguments.order;
		}

		//Get the xml with the request
		body.value = Variables.getXMLRequest(
			Arguments.type, 
			rqsData, 
			This.makeTimestamp()
		);

		Application.service.call('addPaymentAudit', [ 
			{'sqltype':'cf_sql_varchar', 'value': Arguments.order.id},
			{'sqltype':'cf_sql_varchar', 'value': Arguments.type},
			{'sqltype':'cf_sql_varchar', 'value': ''},
			{'sqltype':'cf_sql_varchar', 'value': body.value},
			{'sqltype':'cf_sql_varchar', 'value': 'Request - timestamp: #dateTimeFormat(now(), 'yyyymmyyhhmmssl')#'}
		]);
	
		Super.initiateRequest(attributes=getAttributes(), params=getParams(body));

		rsp = Super.sendRequest();
		rsp['order'] = Arguments.order;
		
		Application.service.call('addPaymentAudit', [ 
			{'sqltype':'cf_sql_varchar', 'value': Arguments.order.id},
			{'sqltype':'cf_sql_varchar', 'value': Arguments.type},
			{'sqltype':'cf_sql_varchar', 'value': ''},
			{'sqltype':'cf_sql_varchar', 'value': serializeJSON(rsp)},
			{'sqltype':'cf_sql_varchar', 'value': 'Response - timestamp: #dateTimeFormat(now(), 'yyyymmyyhhmmssl')#'}
		]);
		//return true = enrolled, false = no enrolled
		return rsp;
	}

	/**
	 * @description check if the request was successful and if the card is enrroled to 3ds
	 * @output false
	 * @hint https://developer.realexpayments.com/#!/api/3d-secure/secure-scenarios
	 */
	private Boolean function get3dsEnrolledResponse() {
		var rsp = This.get3dsResponse().response;
		var resultCode = rsp.result.xmlText;
		var response = false;

		if (resultCode EQ '00' AND rsp.enrolled.xmlText EQ 'Y') {
			response = true;
		}

		return response;
	}
	
	/**
	 * @description XML format Request
	 * @output true
	 * @hint https://developer.realexpayments.com/#!/api/3d-secure/
	 *
	 * @template The xml mustache template to output the request
	 * @order All the neccesary information to complete the order
	 * @timestamp The timestamp of the order
	 */
    private string function getXMLRequest(required string template, required struct order, required string timestamp) {
		var tpl = '';
		var rqs = Arguments.order;
		rqs['merchantId'] = Variables.merchantId;
		rqs['timestamp'] = Arguments.timestamp;
		rqs['sha1hash'] = Variables.calcualteSha1Hash(Arguments.order, Arguments.timestamp);

		//It relies on the mappings for /templates
		savecontent variable="tpl" {
			include '/templates/xml/#Arguments.template#.mustache';
		};

		var body = Application.Mustache.render(
			tpl, 
			rqs
		);
		
        return body;
    }

	/**
	 * @description produce a timestamp
	 * @output false 
	 */
    public function makeTimestamp() {        
       return dateTimeFormat(Now(), 'yyyymmddHHmmss');
	}

	/**
	 * @displayname sha1sha
	 * @hint https://developer.realexpayments.com/#!/api/3d-secure/verify-enrolled
	 * @output false
	 */
    private function calcualteSha1Hash(required order, required timestamp) {
		var formula = Arguments.timestamp & '.' & Variables.merchantId & '.' & Arguments.order.id & '.' & Arguments.order.amount & '.' & Arguments.order.currency & '.' & Arguments.order.card.number;

		/* 
			2nd formula2 = hash(formula).password
			then, sha1hash = hash(formula2)
		*/
		var sha1hash = lCase(
			hash(
				(lCase(hash(formula, 'SHA1')) & '.' & Variables.password),
				'SHA1'
			)
		);		

		return sha1hash;
	}

	/**
	 * @hint Make an order struct
	 * @output true
	 */
	private struct function verify3dsResponse() {
		var order = StructNew();
		if (structKeyExists(Form, 'pares') AND structKeyExists(Form, 'MD')) {
			var md = listToArray(Form.md, ',', false, true);
			for (value in md) {
				var temp = listToArray(value, '=', false);
				if (findNoCase('.', temp[1], 0)) {
					var subtemp = listToArray(temp[1], '.', false);
					if (structKeyExists(order, subtemp[1])) {
						structAppend(order[subtemp[1]], {'#subtemp[2]#': temp[2]} );
					} else {
						structAppend(order, {'#subtemp[1]#': {'#subtemp[2]#': temp[2]} });
					}
				} else {
					structAppend(order, {'#temp[1]#': #temp[2]#});
				}
			}
			structAppend(order, {'pares': Form.pares}, true);
		}
		return order;
	}	
	
}