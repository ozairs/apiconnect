apim.readInputAsJSON(function (error, json) {
	if (error) {
	  apim.setvariable('message.status.code', 500);
	}
	else {
	  // token_scope : scope that will be in the token_scope
	  // api_scope : scope that can be have by the api
	  console.error('OAuth Provider Advanced Scope Check [', JSON.stringify(json), ']');
  
	  //obtain scope from existing OAuth request
	  var token_scope = json.token_scope;
  
	  //application-level scope
	  //set the scope value based on the API assembly set-variable 
	  if (apim.getContext('request.parameters.component') === 'application') {
		if (apim.getvariable('demo.application.x-selected-scope') !== '' &&
		  apim.getvariable('demo.application.x-selected-scope') !== undefined) {
		  token_scope += ' ' + apim.getvariable('demo.application.x-selected-scope');
		  apim.setvariable('message.headers.x-selected-scope', token_scope);
		  console.error('Setting scope value %s', token_scope);
		}
	  }
	  //user-level scope
	  //set the scope value based on the API assembly set-variable 
	  else if (apim.getContext('request.parameters.component') === 'owner') {
		if (apim.getvariable('demo.owner.x-selected-scope') !== '' &&
		  apim.getvariable('demo.owner.x-selected-scope') !== undefined) {
		  token_scope += ' ' + apim.getvariable('demo.owner.x-selected-scope');
		  apim.setvariable('message.headers.x-selected-scope', token_scope);
		  console.error('Setting scope value %s', token_scope);
		}
	  }
	  apim.setvariable('message.status.code', 200);
	}
  });
  