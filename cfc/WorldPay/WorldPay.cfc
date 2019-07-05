component WorldPay accessors="true" {

	
	/**
	 * Initialises the component with the WorldPay service key and default http params
	 * that are used in each API request.
	 */
	public WorldPay function init(string worldPayServiceKey){
		
		variables.defaultHttpParams = [
			{
				"type" 	: "header",
				"name"	: "Authorization",
				"value"	: worldPayServiceKey
			},
			{
				"type" 	: "header",
				"name"	: "Content-type",
				"value"	: "application/json"
			}
		];
		
		return this;
	}
	
	/** 
	 * Pre-authorises an order if using 3DS, completes if not.
	 */
	public struct function placeOrder (string name, string amount, string worldPayToken, string orderType, struct billingAddress, string sessionId, string orderNumber, string userExtRef){
		var response = {};
		var is3DS = true;
		
		//Need to ask Worldpay if this is only for testing
		/* if (orderType EQ "RECURRING" AND (application.environement EQ 'development' OR application.environement EQ 'staging')) {
			is3DS = false;
		} */
		
		//billingAddress['address2'] = '';
		billingAddress["address3"] = '';
		billingAddress["state"] = billingAddress.county;
		structDelete(billingAddress, 'county');
		billingAddress["city"] = billingAddress.town;
		structDelete(billingAddress, 'town');
		billingAddress["postalCode"] = billingAddress.postcode;
		structDelete(billingAddress, 'postcode');
		billingAddress["telephoneNumber"] = '';
		paymentData["token"] = worldPayToken;
		paymentData["orderType"] = orderType;
		paymentData["orderDescription"] = "Undercrackers UserRef:#userExtRef#";
		paymentData["amount"] = amount;
		paymentData["currencyCode"] = "GBP";
		paymentData["name"] = name;
		paymentData["customerOrderCode"] = orderNumber;
		paymentData["billingAddress"] = billingAddress;
		paymentData["is3DSOrder"] = is3DS;
		paymentData["shopperAcceptHeader"] = "acceptheader";
		paymentData["shopperUserAgent"] = cgi.user_agent;
		paymentData["shopperSessionId"] = sessionId;
		paymentData["shopperIpAddress"] = cgi.remote_addr;
		var apiParams = addRequestBody(paymentData);
	
		var apiUrl = "https://api.worldpay.com/v1/orders";
		var requestMethod = "POST";

		response = callApi(apiUrl, requestMethod, apiParams);
		
		return response;
	}
	
	/**
	 * Completes the order after 3DS 
	 */
	public struct function completeOrder(string threeDSresponseCode, string userAgent, string sessionId, string shopperIp, string merchantData){
		var apiUrl = "https://api.worldpay.com/v1/orders/" & merchantData;
		var completePaymentData = {
			"threeDSResponseCode": threeDSresponseCode,
			"shopperAcceptHeader": "acceptheader",
			"shopperUserAgent": userAgent,
			"shopperSessionId": sessionId,
			"shopperIpAddress": shopperIp
		};
		
		var apiParams = addRequestBody(completePaymentData);
		
		response = callApi(apiUrl, "PUT", apiParams);

		return response;
	}
	
	/**
	 * Makes a refund
	 * @orderCode - WorldPay order code 
	 */ 
	public struct function refundOrder (string orderCode) {
		var apiUrl = "https://api.worldpay.com/v1/orders/" & orderCode & "/refund";
		
		var response = callApi(apiUrl, "POST", variables.defaultHttpParams);
		
		return response;
	}
	
	/**
	 * Makes a remote API call
	 */
	private struct function callApi(string apiUrl, string requestMethod, array httpParams){
		var responseContent = "";
		
		var httpService = new http(
			method=requestMethod,
			url=apiUrl
		);
		
		// Add required additional http params for the API call
		for(httpParam in httpParams){		
			if (StructKeyExists(httpParam, "name")) {
				httpService.addParam(type=httpParam.type, name=httpParam.name, value=httpParam.value);
			} else {			
				httpService.addParam(type=httpParam.type, value=Trim(httpParam.value));
			}
			
		}

		var response = httpService.send();
		
		var fileContent = response.getPrefix().fileContent;
	
		// Not all API calls return a valid JSON string (e.g. refund returns an empty string if request is successful). in this case return an empty struct.
		if(IsJSON(fileContent))
			return DeserializeJSON(fileContent);
		else
			return { "success" : true};
		
	}
	
	/**
	 * Adds a body param to the default http params
	 */
	private array function addRequestBody(struct requestBody){
		var httpParams = variables.defaultHttpParams;
		var bodyRequest = {
			"type" 	: "body",
			"value": SerializeJSON(requestBody)
		};
		
		ArrayAppend( httpParams, bodyRequest);
		
		return httpParams;
	}
}