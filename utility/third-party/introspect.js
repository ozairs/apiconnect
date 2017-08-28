apim.readInputAsBuffer(function (error, buffer) {
	if (error) {
		apim.setvariable('message.status.code', 500);
	}
	else {
		var response = { "active": true };

		//simulate OAuth provider that returns scopes as part of the introspection lookup
		if (apim.getvariable('demo.introspect.response.scope') !== '' &&
			apim.getvariable('demo.introspect.response.scope') !== undefined) {
			response['scope'] = apim.getvariable('demo.introspect.response.scope');
		}

		//TESTING ONLY: include the basic-auth header in the request back in the response
		response['basic-authorization'] = apim.getContext('request.authorization');
		//TESTING ONLY: include the input body from the request back in the response
		response['input_body'] = buffer.toString();
		//set the response context
		apim.output('application/json');
		apim.setvariable('message.status.code', 200);
		console.error ('>> oauth introspection - returning response %s', JSON.stringify(response));
		session.output.write(JSON.stringify(response));
	}
});


