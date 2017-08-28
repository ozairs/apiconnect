//username and confirmation code are passed via the HTTP Authorization header
var reqauth = apim.getvariable('request.authorization').split(' ');
var splitval = new Buffer((reqauth[1] || ''), 'base64').toString('utf8').split(':');
var username = splitval[0] || '';
var password = splitval[1] || '';

//verify the username and confirmation code (if using the defaults as configured in the API assembly)
if (username === apim.getvariable('demo.identity.redirect.username') &&
	password === apim.getvariable('demo.identity.redirect.confirmation')) {
	apim.setvariable('message.status.code', 200);

	//if third-party authentication service provided granular scope options, 
	//then it will need to return them via the response header, `x-selected-scope`
	if (apim.getvariable('demo.authenticate-url.x-selected-scope') !== '' &&
		apim.getvariable('demo.authenticate-url.x-selected-scope') !== undefined) {
		apim.setvariable('message.headers.x-selected-scope', apim.getvariable('demo.authenticate-url.x-selected-scope'));
	}
	//if third-party authentication service wants to use a different username, 
	//then it will need to return them via the response header, `api-authenticated-credential`
	if (apim.getvariable('demo.api-authenticated-credential') !== '' &&
		apim.getvariable('demo.api-authenticated-credential') !== undefined) {
		apim.setvariable('message.headers.api-authenticated-credential', apim.getvariable('demo.api-authenticated-credential'));
	}
	//if third-party authentication service wants to insert metadata into the token, 
	//then it will need to return them via the response header, `api-oauth-metadata-for-accesstoken`	
	if (apim.getvariable('demo.authenticate-url.metainfo.4.token') !== '' &&
		apim.getvariable('demo.authenticate-url.metainfo.4.token') !== undefined) {
		apim.setvariable('message.headers.api-oauth-metadata-for-accesstoken', apim.getvariable('demo.authenticate-url.metainfo.4.token'));
	}
	//if third-party authentication service wants to insert metadata into the payload, 
	//then it will need to return them via the response header, `api-oauth-metadata-for-payload`	
	if (apim.getvariable('demo.authenticate-url.metainfo.4.payload') !== '' &&
		apim.getvariable('demo.authenticate-url.metainfo.4.payload') !== undefined) {
		apim.setvariable('message.headers.api-oauth-metadata-for-payload', apim.getvariable('demo.authenticate-url.metainfo.4.payload'));
	}
}
else {
	apim.setvariable('message.status.code', 401);
}