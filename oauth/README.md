# Explore digital use cases based on OAuth

**Authors** 
* [Ozair Sheikh](https://github.com/ozairs)

**Prequisites**

* For testing, you will to download [Postman](https://www.getpostman.com/). 
* Download the Postman collection [here](https://www.getpostman.com/collections/951c78382a60b7f7be67)

**Instructions:** 

In this tutorial, you will import an existing OAuth definition and learn about the various OAuth use cases (ie grant types). Using a postman collection, you will submit requests to obtain an access token and learn about the various parameters required for two-legged (resource owner & client credential) and three-legged OAuth flows (implicit grant and access code).

For more information on setting up OAuth, see the article [here](https://www.ibm.com/support/knowledgecenter/en/SSFS6T/com.ibm.apic.toolkit.doc/tutorial_apionprem_security_OAuth.html).

1. Import API definitions file: oauth, utility and Weather. Click the **Add (+)** button and select **Import API from a file or URL**. 
	* [https://github.com/ozairs/apiconnect/blob/master/oauth/weather-provider-api_1.0.0.yaml]() 
	* [https://github.com/ozairs/apiconnect/blob/master/oauth/oauth_1.0.0.yaml](). 
	* [https://github.com/ozairs/apiconnect/blob/master/oauth/utility_1.0.0.yaml](). 

2. Scroll down to the OAuth section to examine the grant types.
	* **Implicit (public)**: implicit grant type to obtain an access token. The resource owner credentails are provided in a Basic Auth header. The access token is available in the Location header. Click Headers to view the access token `https://www.getpostman.com/oauth2/callback#access_token=`
	* **Password (resource-owner)**: resource owner grant type to obtain an access token. The resource owner provides its credentials to the OAuth client to obtain an access token.
	* **Application (client credentials)**: client credential grant type to obtain an access token. No resource owner credentials are needed, just the client id and secret.
	* **Access Code (code)**: the resource owner provides access to its resource to a third-party OAuth application without sharing its credentials. Two steps are required to obtain the access token.
	
3. Test the unprotected  `/current` APIs
	Using either the built-in test tool (switch back to the Weather API) or curl, make sure you can access the APIs.
	```
	$ curl https://127.0.0.1:4001/current?zipcode=90210 -H "X-IBM-Client-Id: default" -k
	{"zip":"90210","temperature":62,"humidity":90,"city":"Beverly Hills","state":"California","platform":"Powered by IBM API Connect"}
	```
4. Protect API with OAuth Password flow
	1. Open the **Weather Provider API** and scroll down to **Security Definitions**. Click the + button and select **OAuth**.
	2. Enter the name `oauth-password` and select the **Password** flow. Enter the **Token URL** value `https://127.0.0.1/oauth2/token` (replace the hostname if your using a different value).
	3. Scroll down to the scopes section and enter the scopes `weather`.
	4. In the **Security** section, select **oauth-password (OAuth)** and the scope `weather`.
	5. Save the API definition.

5. Test the Weather API, you will now get an error because the API is protected using OAuth. In the next step you will obtain an access token to call the same APIs
	```
	$ curl https://127.0.0.1:4001/current?zipcode=90210 -H "x-ibm-client-id: default" -k
	{ "httpCode":"401", "httpMessage":"Unauthorized", "moreInformation":"This server could not verify that you are authorized to access the URL" }
	```
6. Obtain an access token from the OAuth provider (using the resource owner grant type) using Postman.
	1. Open Postman and select **File -> Import -> Import from Link** and enter the value https://www.getpostman.com/collections/951c78382a60b7f7be67 or you can optionally import from the file `OAuth.postman_collection.json` in your local directory.
	2. Open the request called `OAuth Password`. Select the **Body** link and notice that a default client id of `default` and client secret of `SECRET` is pre-configured. Adjust the values if your endpoint is different than `https://127.0.0.1:4001`.
	3. Submit the request and validate that you get back an access token.
	```
	{
		"token_type": "bearer",
		"access_token": "<sanitized>",
		"expires_in": 3600,
		"scope": "weather",
		"refresh_token": "<sanitized>"
	}
	```
	4. Copy the access token so it remains on your clipboard. You are now ready to call the Weather API!
7. Open the Weather request and select the **Headers** tab. Enter the previously copied access token into the Authorization header field and click **Send** to validate that the request is successful.
	```
	{
		"zip": "90210",
		"temperature": 66,
		"humidity": 78,
		"city": "Beverly Hills",
		"state": "California",
		"platform": "Powered by IBM API Connect"
	}
	```

When using the API Connect developer toolkit with **OAuth Access code** flow, you will need to redirect the application to an OAuth client to exchange the authorization code for an access code. This is typically done in an OAuth application, but we can use a couple of techniques to streamline the test case.

1. Configure environment for OAuth Access Code 
	1. Open a command prompt and make sure your in the project directory (ie same directory as the project yaml files). Enter the command 
		`apic config:set oauth-redirect-uri=https://www.getpostman.com/oauth2/callback`
	2. Verify that the `oauth-redirect-uri` is set within the file `.apiconnect/config`.
		`oauth-redirect-uri: 'https://www.getpostman.com/oauth2/callback'`
	3. Open Postman Preferences and disable **Automatically follow redirects**.
	![alt](images/postman.png)

2. Protect Weather API with OAuth Access Code flow  
	1. Open the **Weather Provider API** and scroll down to **Security Definitions**. Click the + button and select **OAuth**.
	2. Enter the name `oauth-accesscode` and select the **Access Code** flow. Enter the **Authorize URL** value `https://127.0.0.1/oauth2/authorize` and **Token URL** value `https://127.0.0.1/oauth2/token`. (change the hostname to reflect your environment if needed).
	3. Scroll down to the scopes section and enter the scopes `weather`.
	4. In the **Security** section, click the + button to create a new option and select **oauth-accesscode (OAuth)** and the scope `weather`.
	4. Save the API definition.	
	**Note:** Multiple security definitions allow you provide multiple options to satisfy consumer security requirements.

3. Open the request called `OAuth Access Code`. Adjust the values if your endpoint is different than `https://127.0.0.1:4001`.
	1. Submit the request and make sure you get the following response:
	```
	<?xml version="1.0" encoding="UTF-8"?>
	<html>
		<body>Go ahead</body>
	</html>
	```
	The Access Code flow requires an additional step to exchange an authorization code for an access token. This is usually done by an OAuth application but we will simplify it by simulating the OAuth application.
	2. Click the Headers tab and copy the value after `code=`
	3. Copy the `code` so it remains on your clipboard.
	4. Open the `OAuth AC to Token` request and click the **Body** tab. Paste the code value into the `code` field. Click **Send** and verify you receive an access token.
4. Open the Weather request and select the **Headers** tab. Enter the previously copied access token into the Authorization header  after the `Bearer` string and click **Send**. Validate that the request is successful.
	```
	{
		"zip": "90210",
		"temperature": 66,
		"humidity": 78,
		"city": "Beverly Hills",
		"state": "California",
		"platform": "Powered by IBM API Connect"
	}
	```

In this tutorial, you learned how to obtain an access token for the password and access code flow and use that token to call a protected API service.

**Next Tutorial**: [Manage digital applications with OAuth lifecycle management](../master/oauth-token-mgmt/README.md)