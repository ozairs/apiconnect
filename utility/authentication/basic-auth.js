var querystring = require ('querystring');

console.error(">> basic-auth authentication service");
console.error(">> request: original URL %s", apim.getvariable('message.headers.x-uri-in'));

//parse the input URL to extract query params
var requrl = querystring.parse(apim.getvariable('message.headers.x-uri-in').split('?')[1]);
console.error('parsed query param: request (jwt) %s', requrl['request']);

// obtain the username/password from the basic auth header
var reqauth = apim.getvariable('request.authorization').split(' ');
var splitval = new Buffer((reqauth[1] || ''), 'base64').toString('utf8').split(':');
var username = splitval[0] || '';
var password = splitval[1] || '';

// authentication check: validates the the username/passed passed in via query params against the basic auth values
apim.console.debug('user credential : [' + username + ':' + password + ']');
if (username === apim.getvariable('request.parameters.username') &&
	password === apim.getvariable('request.parameters.password')) {
	//authenticatedUser field is the identity value used within the access token
	session.output.write({ "authenticatedUser": username });
	if (apim.getvariable('demo.api-authenticated-credential') !== '' &&
		apim.getvariable('demo.api-authenticated-credential') !== undefined) {
		apim.setvariable('message.headers.api-authenticated-credential', apim.getvariable('demo.api-authenticated-credential'));
	}

	//optional: if scope validation needs to be done
	var scope = apim.getvariable('request.headers.x-requested-scope');
	/* return scope with description */
	if (apim.getvariable('demo.authenticate-url.x-selected-scope-w-desc') !== '' &&
		apim.getvariable('demo.authenticate-url.x-selected-scope-w-desc') !== undefined) {
		var jsonscope = JSON.parse(apim.getvariable('demo.authenticate-url.x-selected-scope-w-desc'));
		if (scope !== undefined && scope !== '') {
			var token = scope.split(' ');
			for (var i = token.length; i--;) {
				jsonscope[token[i]] = '';  // setting the value to '', will allow apic to pick up its own description in the provider
			}
		}
		apim.setvariable('message.headers.x-selected-scope', JSON.stringify(jsonscope));
	}

	//optional: if metadata needs to be injected within the access token
	if (apim.getvariable('demo.authenticate-url.metainfo.4.token') !== '' &&
		apim.getvariable('demo.authenticate-url.metainfo.4.token') !== undefined) {
		apim.setvariable('message.headers.api-oauth-metadata-for-accesstoken', apim.getvariable('demo.authenticate-url.metainfo.4.token'));
	}

	//optional: if metadata needs to be injected within the payload
	if (apim.getvariable('demo.authenticate-url.metainfo.4.payload') !== '' &&
		apim.getvariable('demo.authenticate-url.metainfo.4.payload') !== undefined) {
		apim.setvariable('message.headers.api-oauth-metadata-for-payload', apim.getvariable('demo.authenticate-url.metainfo.4.payload'));
	}
	apim.setvariable('message.status.code', 200);
	apim.output('application/json');
}
else {
	apim.setvariable('message.status.code', 401);
}