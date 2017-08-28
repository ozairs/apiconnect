// output to the system logs, the input parameters passed in the URL query string
console.error('original-url : ', apim.getContext('request.parameters.original-url'));
console.error('app-name : ', apim.getContext('request.parameters.app-name'));
console.error('appid : ', apim.getContext('request.parameters.appid'));
console.error('org : ', apim.getContext('request.parameters.org'));
console.error('orgid : ', apim.getContext('request.parameters.orgid'));
console.error('catalog : ', apim.getContext('request.parameters.catalog'));
console.error('catalogid : ', apim.getContext('request.parameters.catalogid'));
console.error('provider : ', apim.getContext('request.parameters.provider'));
console.error('providerid : ', apim.getContext('request.parameters.providerid'));

// perform the actual authentication / authorization

//extract the username and confirmation code once the user is successfully authenticated and authorized
var username = apim.getvariable('demo.identity.redirect.username');
var confirmationCode = apim.getvariable('demo.identity.redirect.confirmation')

//build the callback URL using the original URL passed into the service
var origUrl = decodeURIComponent(apim.getContext('request.parameters.original-url') ||
	'');
var location = origUrl + '&username=' + username + '&confirmation=' + confirmationCode;

//set the response headers to trigger a redirect back to API Connect
apim.setvariable('message.status.code', 302);
apim.setvariable('message.headers.location', location);
console.error('redirect back to apic [', location, ']');