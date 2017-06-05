# 5. Protect access to API services with Auth0 & JWT

**Authors** 
* [Shiu-Fun Poon](https://github.com/shiup)
* [Ozair Sheikh](https://github.com/ozairs)

**Prerequisites:** 

* API Connect Developer Toolkit 5.0.7.1
* Import the API definitions file from **https://github.com/ozairs/apiconnect/blob/master/jwt/weather-provider-api_1.0.0.yaml**. See instructions [here](https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.apionprem.doc/create_api_swagger.html)

In this tutorial, you will control access to the backend service by requiring a valid JWT (JSON Web Token). For more information about JWT, see [here](https://jwt.io). JWT is a JSON-based token that provides a series of claims that are cryptographically verifyable. The base claim is a subject-audience pair which asserts the token for a particular user.

In our scenario, the API definition requires a valid JWT token generated from a trusted identity provider - [auth0.com](https://auth0.com). 

The following instructions provide guidance on how to setup an auth0 account to issue JWT tokens. Its not a comprehensive step-by-step guide, so we would recommend you check out their [docs](https://auth0.com/docs).

**Instructions:** 

*Auth0 Setup*

1. Login to [auth0](https://www.auth0.com) and create an auth0 account.
2. Click the **APIs** link from the nav bar and create a new API, called `Weather` and identifier with `<yourid>.apiconnect.com`. Click Create to complete the API definition.
3. In the **Quick Start** section make a note of the jwsURI:
	```
	secret: jwks.expressJwtSecret({
			.
			.
			jwksUri: "https://ozairs.auth0.com/.well-known/jwks.json"
		}),
	```
4. In the **Scopes** section create new scopes called `read` and `write` and add a description.
5. In the **Non Interactive Clients** section, expand the `Weather Client` and select the previously created scopes and click **Update**. Click **Continue** to accept the warning message.
6. In the **Test** section, copy and paste the curl command in a command prompt (if curl is unavailable, use other alternatives).
	```
	$ curl --request POST \
	>   --url https://ozairs.auth0.com/oauth/token \
	>   --header 'content-type: application/json' \
	>   --data '{"client_id":"<client_id>","client_secret":"<client_secret>","audience":"https://ozairs.apiconnect.com/","grant_type":"client_credentials"}'
	{"access_token":"<token>","expires_in":86400,"scope":"write read","token_type":"Bearer"}
	```
	In the real-world use case, a web / mobile application will issue this request to obtain an access token.

Lets switch back to API Connect and add a JWT policy.

*API Connect Setup*

1. In the API designer, click the **Design** tab. Click Paths and click the + button to add a new Path named `/weather` to the existing Weather API. Leave the default GET operation. Click Save once complete.
2. Click the **Assemble** tab and select the existing  `operation-switch` policy. Add a new case for the `get /weather`.
3. For the `get /weather` case, add the following policies to obtain the jwk key and use it to validate the JWT token:
	1. Add a `Invoke` action, named `get-jwk-key` with the following:
    	* URL: https://ozairs.auth0.com/.well-known/jwks.json
		* Cache Type: Time to Live
		* Cache Time to Live: 900
		* Uncheck Stop on Error
		* Response object variable: rsa256-key

  	2. Add a GatewayScript policy to extract the JSON Web Key (JWK) from the previous `Invoke` policy and save it as a context variable
	```
	var rsa256Key = apim.getvariable('rsa256-key');
	apim.setvariable('jwk-key', JSON.stringify(rsa256Key.body.keys[0]));
	```

  	3. Add a `Validate JWT` policy with the following:
		* JWT: request.headers.authorization
		* Output Claims: decoded.claims
		* Issuer Claim: .*\.auth0\.com\/
		* Audience Claim: .*\.apiconnect\.com
		* Verify Crypto JWK variable name: jwk-key
		
		**Note**: You can create a stronger regular expression in the issuer and audience claims field for enhanced security if needed. 

	4. Add a GatewayScript policy to return the decoded claims
	```
	apim.setvariable('message.body', apim.getvariable('decoded.claims'));
	```
	![alt](images/jwt-validate.png)

	Notice that the `get /weather` does not have a backend Invoke policy although it would in a real-world scenario. We are simply returning the decoded claims to verify the JWT token was successfully validated.
	
3. Test the policy.
	A real-world (mobile) application will use two endpoints:
	1. **Auth0**: obtain the JWT token against the Auth0 authorization server directly (ie no API Connect involvement).
	```
	curl --request POST \
	>   --url https://ozairs.auth0.com/oauth/token \
	>   --header 'content-type: application/json' \
	>   --data '{"client_id":"<client_id>","client_secret":"<client_secret>","audience":"https://ozairs.apiconnect.com/","grant_type":"client_credentials"}'
	```
	2. **API Connect**: validate the JWT digital signature using a JWK (obtained remotely)
		1. Enter the following curl command, replacing the <access_token> with the previous `access_token` value into the Authorization header.
		```
		https://127.0.0.1:4001/weather -H "X-IBM-Client-Id: default" -H "Authorization: Bearer <access_token>" -k
		```
		2. The response will contain the decoded JWT
		```
		{
		 "iss": "https://ozairs.auth0.com/",
		 "sub": "gHXm6ss79Jm866TYdyMCtPyyZ25iFpWq@clients",
		 "aud": "https://ozairs.apiconnect.com/",
		 "exp": 1494354567,
		 "iat": 1494268167,
		 "scope": "write read"
		}
		```

For more information about JWT, you can read the link [here](https://developer.ibm.com/apiconnect/2016/08/16/securing-apis-using-json-web-tokens-jwt-in-api-connect-video-tutorial/)

Summary of the JWT security actions:
 - `jwt-validate`: validate the identity assertion claims from a jwt token
 - `jwt-generate`: generate jwt token with identity assertion claims

In this tutorial, you used a JWT validate policy to verify the JSON Web signature (JWT) of a JWT token that was generated from auth0 (external identity provider).