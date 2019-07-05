component accessors='true' output='true' displayname='Routes' hint='Routes Handler' {

	property name='mappings' type='array';
	property name='pageNoFound' type='struct';
	property name='login' type='struct';

	CONS.FOWARDSLASH = '/';
	CONS.BACKSLASH = '\';
	CONS.404 = '404';
	CONS.500 = '500';
	CONS.GET = 'GET';
	CONS.POST = 'POST';
	
	CONS.VIEWS = 'views';
	CONS.PACKAGE = 'packages';
	CONS.CONTROLLERS = 'controllers';
	CONS.TEMPLATE = 'template';
	CONS.HOME = 'home';
	CONS.NAME = 'name';
	CONS.URL_QUERY = 'q';
	CONS.CFM = '.cfm';
	CONS.CFC = '.cfc';
	CONS.ORIGINAL_PAGE_REQUEST_PARAM = 'target';
	CONS.VALIDATE_EXTREF = '[a-f\d]{8}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{12}';

	CONS.EX.NO_ARGUMENTS_FOR_ROUTE = 'NoArgumentsForRoute';
	CONS.EX.NO_PAGE_AVAILABLE = 'NoPageAvailable';
	CONS.EX.NO_PACKAGE_AVAILABLE = 'NoPackageAvailable';
	CONS.EX.NO_LOGIN_AVAILABLE = 'NoLoginAvailable';

	CONS.ONE = 1;

	public function init (required struct noFound, struct login = {uri='', controller='', callback='', forward=''}) {
		This.setMappings([]);
		This.get(
			uri=(structKeyExists(Arguments.noFound, 'uri') ? Arguments.noFound.uri : ''),
			controller=(structKeyExists(Arguments.noFound, 'controller') ? Arguments.noFound.controller : ''), 
			callback=(structKeyExists(Arguments.noFound, 'callback') ? Arguments.noFound.callback: ''), 
			secure=false,
			noFoundPage=true
		);
		if (len(Arguments.login.uri)) {
			Variables.addNewMapping(
				method=CONS.GET,
				uri=(structKeyExists(Arguments.login, 'uri') ? Arguments.login.uri : ''),
				controller=(structKeyExists(Arguments.login, 'controller') ? Arguments.login.controller : ''),
				callback=(structKeyExists(Arguments.login, 'callback') ? Arguments.login.callback : ''),
				uriRegex={},
				referer='',
				secure=false,
				noFoundPage=false,
				login=true,
				forward=(structKeyExists(Arguments.login, 'forward') ? Arguments.login.forward : '/')
			);
		}
		return this;
	}

	public function get(required string uri, string controller='', callback='', struct uriRegex = StructNew(), string referer = '', boolean secure=false, boolean noFoundPage=false) {
		Variables.addNewMapping(
			CONS.GET,
			Arguments.uri,
			Arguments.controller,
			Arguments.callback,
			Arguments.uriRegex,
			Arguments.referer,
			Arguments.secure,
			Arguments.noFoundPage
		);
	}

	public function post(required string uri, string controller='', callback='', struct uriRegex = StructNew(), string referer = '', boolean secure=false, boolean noFoundPage=false) {
		Variables.addNewMapping(
			CONS.POST,
			Arguments.uri,
			Arguments.controller,
			Arguments.callback,
			Arguments.uriRegex,
			Arguments.referer,
			Arguments.secure,
			Arguments.noFoundPage
		);
	}

	public void function view(page = '') {
		var folderFile = listToArray(Arguments.page, '.');
		var path = '#CONS.BACKSLASH##CONS.PACKAGE##CONS.BACKSLASH#';
		for (var i = CONS.ONE; i LTE ArrayLen(folderFile); i += CONS.ONE) {
			if (i EQ ArrayLen(folderFile)) {
				path &= folderFile[i] & CONS.CFM;
			} else {
				path &= folderFile[i] & CONS.BACKSLASH;
			}
		}

		if (fileExists( expandPath(path) )) {
			include path;
		} else {
			throw(message='The package your are trying to access [[ #path# ]] doesn''t exist. Please add the package to stop this error.', type=CONS.EX.NO_PACKAGE_AVAILABLE);
		}
	}

	public boolean function validMapping(required string uri) {
		var mapping = Variables.getMapping(uri=Arguments.uri, verb=CONS.GET);
		return (mapping.uri EQ arguments.uri ? true : false);
	}

	public void function verify() {
		var rqs = (StructKeyExists(Url, CONS.URL_QUERY) ? Url.q : CONS.FOWARDSLASH);
		var mapping = Variables.getMapping(rqs);
		//First, check if this is a secure page and user is not authenticated
		if (mapping.secure AND NOT Variables.isAuth()) {
			//not auth -redirect
			var login = this.getLogin();
			//Ensure login mapping is defined
			if (isDefined('login')) {
				/*
					redirect to login but rememeber the page
					If login is the root directory don't add /
				*/
				var redirect = (reFindNoCase('^\/(.)*$', login.uri) ? login.uri : '/#login.uri#');
				redirect &= '?target=' & mapping.uri;

				location(url= redirect, addtoken=false);
			} else {
				throw(message='You have specified uri [[#Url.q#]] as secure, but you have not set a login route', type=CONS.EX.NO_LOGIN_AVAILABLE);	
			}
		} 
		
		//Make the callback
		if (isClosure(mapping.callback)) {
			var referer = (reFindNoCase(mapping.referer, CGI.HTTP_REFERER));
			mapping.callback(This, mapping, referer, mapping.info.params);
		}

		//The Controller is initiated
		var validController = This.initController(mapping.controller.name, mapping.controller.method, mapping.info.params);
		
		if (NOT validController AND NOT isClosure(mapping.callback)) {
			throw(message='Please add a controller or a callback to render your route [[#mapping.uri#]]. It you have, it could be that your controller has been misspelled', type=CONS.EX.NO_ARGUMENTS_FOR_ROUTE);
		}
	}

	public Boolean function initController(string controller = '', string method = '', struct args = {}) {
		var parts = listToArray(arguments.controller, '.');
		var path = '/controllers';
		for (part in parts) {
			path &= '/#part#';			
		}
		
		path &= '.cfc';
		var compoPath = CONS.CONTROLLERS & '.' & Arguments.controller;
		if (fileExists( expandPath(path) )) {
			var compo = getComponentMetaData( CONS.CONTROLLERS & '.' & Arguments.controller );
			
			if (NOT structKeyExists(compo, 'functions')) {
				return false;
			}

			if (Variables.isValueInArrayOfStructs(compo.functions, CONS.NAME, Arguments.method)) {
				invoke('#CONS.CONTROLLERS#.#Arguments.controller#', Arguments.method, Arguments.args);
				return true;
			}
		} 
		
		return false;
	}

	private function addMapping(required struct mapping) {
		var mappings = This.getMappings();
		arrayAppend(mappings, mapping, true);
		This.setMappings(mappings);
	} 

	private struct function getMapping(required string uri, login = false, verb = CGI.REQUEST_METHOD) {
		var mappings = This.getMappings();
		for (var i = CONS.ONE; i LTE ArrayLen(mappings); i += CONS.ONE) {
			var temp = Variables.getInfoForMapping(Arguments.uri, mappings[i], Arguments.verb);
			
			if (temp.info.valid) {	
				return temp;
			}
		}
		//If the mapping wasn't found then get the pagenofound mapping
		var pageNoFound = This.getPageNoFound();		
		return Variables.getInfoForMapping(pageNoFound.uri, pageNoFound, Arguments.verb);
	}

	private struct function getInfoForMapping(required string uri, required struct mapping, required verb) {
		/* TODO: mapping.controller sometimes is string and others is a struct, make it always come as struct with name and method */
		var controller = (isStruct(Arguments.mapping.controller) ? Arguments.mapping.controller.name : Arguments.mapping.controller);
		Arguments.mapping['info'] = Variables.validateUri(Arguments.mapping,  Arguments.uri, Arguments.verb);
		Arguments.mapping.controller = Variables.getControllerStruct(controller);
		return Arguments.mapping;
	}

	private struct function getControllerStruct(required string controller) {
		var rsp = {
			'name':'',
			'method': CONS.HOME
		};
		var controllerPath = listToArray(Arguments.controller, '.');
		if (arrayLen(controllerPath) GT 1) {
			rsp.method = controllerPath[arrayLen(controllerPath)];
			for (var i=1; i LTE arrayLen(controllerPath); i+=1 ) {
				if (i NEQ arrayLen(controllerPath)) {
					rsp.name &= ( i EQ 1 ?  '' : '.') & controllerPath[i];
				}
			}		
		} else {
			rsp.name = Arguments.controller;
		}
		return rsp;
	}

	private void function addNewMapping(string method = CONS.GET, required string uri, required string controller, required callback, required struct uriRegex = StructNew(), required string referer, required Boolean secure, boolean noFoundPage=false, boolean login=false, string forward='') {
		var mapping = {
			'method': Arguments.method,
			'uri': Arguments.uri,
			'controller': Arguments.controller,
			'callback': Arguments.callback,
			'uriRegex': Arguments.uriRegex,
			'referer': Arguments.referer,
			'secure': Arguments.secure
		};

		if (Arguments.noFoundPage) {
			This.setPageNoFound(mapping);
		} else {
			if (Arguments.login) {
				mapping['forward'] = Arguments.forward;
				This.setLogin(mapping);
			}
			Variables.addMapping(mapping);
		}
	}

	private Struct function validateUri(required struct mapping, required string uri, required verb) {
		var pathParts = listToArray(Arguments.uri, CONS.FOWARDSLASH);
		var controllerInfo = '';
		var rsp = {
			'valid': false,
			'uri': Arguments.uri,
			'params': StructNew('ordered')
		};
		
		if (NOT structIsEmpty(mapping.uriRegex) ) {
			var pathPartsMap = listToArray(mapping.uri, CONS.FOWARDSLASH);
			var partsCount = arrayLen(pathParts);			
			var patternUrl = variables.validatePatternUrl(
				pathParts,
				listToArray(mapping.uri, CONS.FOWARDSLASH),
				mapping.uriRegex
			);

			rsp.valid = (patternUrl.valid AND arguments.mapping.method EQ arguments.verb);
			rsp.params = patternUrl.params;
		}
			
		if (Arguments.mapping.uri EQ Arguments.uri) {
			var temp = StructNew('ordered');
			
			if (arrayLen(pathParts) EQ 1) {
				rsp.uri = pathParts[1];
			} else if (arrayLen(pathParts) EQ 2) {
				for (part in pathParts) {
					temp[part] = part;
				}

				rsp.uri = pathParts[1];
				rsp.params = temp;
			}
			
			rsp.valid = (Arguments.mapping.uri EQ Arguments.uri AND Arguments.mapping.method EQ Arguments.verb);
		}

		return rsp;
	}

	/**
	 * @output false
	 * @hint Is the user Auth
	 */
	private Boolean function isAuth() {
		var extRef = session.user.getExtref();
		var validate = reMatchNoCase(CONS.VALIDATE_EXTREF, extRef);
		
		return ( ArrayLen(validate) ? 
						(validate[CONS.ONE] EQ extRef) : false );
	}

	private function isValueInArrayOfStructs(array anArray, key, value) {
		for (var i=CONS.ONE; i LTE ArrayLen(Arguments.anArray); i += CONS.ONE) {
			if (Arguments.anArray[i][Arguments.key] EQ Arguments.value) {
				return true;
			}
		}
		return false;
	}

	private function validatePatternUrl(required array urlPath, required array expected, regex = {}, result = {valid=true, params:{}}) {
		var valid = false;

		//exit recursive if arrays are not the same length
		if (ArrayLen(Arguments.urlPath) NEQ arrayLen(Arguments.expected)) {
			Arguments.result.valid = false;
			return Arguments.result;
		}

		//exit recursive with the result so far
		if ( arrayIsEmpty(Arguments.urlPath) ) {
			return result;
		}
		
		//When the path part is the same
		if (urlPath[1] EQ Arguments.expected[1]) {
			valid = true;
		} else {
			//clean the pattern
			var regexKey = REReplaceNoCase(
				REReplaceNoCase(Arguments.expected[1], '{{', '', 'ALL'),
				'}}',
				'',
				'ALL'
			);
			//If the current path part meet the patther
			if (structKeyExists(Arguments.regex, regexKey) AND ArrayLen(REMatch(Arguments.regex[regexKey], urlPath[1])) ) {
				var temp = StructNew('ordered');
				temp[regexKey] = urlPath[1];
				valid = true;
				structAppend(Arguments.result.params, temp);
			}
		}

		Arguments.result.valid = (Arguments.result.valid AND valid);

		arrayDeleteAt(Arguments.urlPath, 1);
		arrayDeleteAt(Arguments.expected, 1);
		return Variables.validatePatternUrl(Arguments.urlPath, Arguments.expected, Arguments.regex, Arguments.result);
	}
	
}