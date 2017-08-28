// @ozair @spoon
var out = { "message": "Greeting! Hello World" };
out.whoami = apim.getContext('api.endpoint.address');
session.output.write(JSON.stringify(out));
apim.output("application/json");