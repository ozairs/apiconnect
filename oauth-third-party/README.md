# Enforce API access with Third-party OAuth providers

**Authors** 
* [Ozair Sheikh](https://github.com/ozairs)

Special thanks to [Shiu-Fun Poon](https://github.com/shiup) for the API assets and knowledge transfer. 

**Prerequisites:** 

* For testing, you will to download [Postman](https://www.getpostman.com/). 
* Download the Postman collection [here](https://www.getpostman.com/collections/9ab248322bd2f0a75eea)

**Instructions:** 

API Connect ships with a built-in OAuth provider that provides complete OAuth authorization server capabilities, such as grant validation, identity extraction, authentication, authorization, token management, introspection, and more. The OAuth provider in API connect is able to generate and validate access tokens to secure backend resources. More specifically, when API Connect generates the OAuth token, it knows exactly how to validate it. If your using a non-API Connect OAuth authorization server to generate OAuth tokens (such as IBM Security Access Manager (ISAM)), then API Connect can still validate those token but you will need to tell it how to validate non-API connect generated tokens. In this tutorial, you will learn how to configure API Connect to validate a third-party access token using the introspection callout feature, based on [RFC 7622](https://tools.ietf.org/html/rfc7662). Even if the third-party oauth provider does not support the standard introspection lookup but supports an alternative approach to token validation, you can proxy to a microservice that can perform the token validation based on its supported interface. In this scenario, API Connect performs no token management capabilities (generate, revoke, refresh or introspect access tokens), you will need to use the third-party OAuth server directly for these operations.

For more information on setting up OAuth, see the article [here](https://www.ibm.com/support/knowledgecenter/en/SSFS6T/com.ibm.apic.toolkit.doc/tutorial_apionprem_security_OAuth.html).

1. Import API definitions file: oauth, third-party-oauth-provider, utility and Weather. Click the **Add (+)** button and select **Import API from a file or URL**. 
	* [https://raw.githubusercontent.com/ozairs/apiconnect/master/oauth-third-party/weather-provider-api_1.0.0.yaml]() 
	* [https://raw.githubusercontent.com/ozairs/apiconnect/master/oauth-third-party/oauth_1.0.0.yaml](). 
	* [https://raw.githubusercontent.com/ozairs/apiconnect/master/oauth-third-party/utility_1.0.0.yaml]().
	* [https://raw.githubusercontent.com/ozairs/apiconnect/master/oauth-third-party/third-party-oauth-provider_1.0.0.yaml]().  

	You can configure a third-party OAuth server to generate an access token. Since we don't have a third-party OAuth server in our environment, we will simulate one using API Connect OAuth server. Its probably not the best example, but it will be sufficient to demonstrate the point.

	The typical developer flow for this type of scenario is the following:
	1. Application developer creates an application in the developer portal and obtains a client id and client secret.
	2. During the creation of the client id and secret from (1), the Third-party OAuth server will also need the same client id and secret as part of its OAuth server configuration. The dev portal will need to push the same information to the OAuth third-party server. This requirement is outside the scope of this tutorial. For more information, see [here](https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.devportal.doc/tutorial_syncing_application_credentials.html)
	3. After the App developer creates an application, it wil make a note of the published OAuth endpoint in the dev portal, which should point directly to the third-party OAuth provider. The API enforcement point will still be API Connect. This is the key point, API Connect does not participate in the OAuth authentication flow, it will ONLY perform token validation to protect access to the API resource.
		**Example**: 
		* OAuth endpoints: `https://<third-party-oauth-provider>/oauth2/token` & `https://<third-party-oauth-provider>/oauth2/authorize`
		* API Resource endpoint: `https://<api-connect-endpoint>/weather/current`
	4. The App developer application will obtain an access token from the third-party OAuth endpoint. It will then call the API Resource endpoint (in API Connect).
	5. API Connect OAuth provider will extract the token from the message and perform an OAuth introspection lookup against the third-party OAuth provider (either directly or via a microservice) to validate the OAuth token. If successful, it will then execute the Assembly policies, where it will proxy the request to the backend API resource.

	The following diagram summarizes the scenario:

	![alt](images/oauth_introspection.jpg)

2. Navigate to the folder `https://github.com/ozairs/apiconnect/blob/master/utility/third-party` directory and open the `introspect.js` file. This file will simulate the OAuth introspection endpoint in the API definition.
	
API Connect defines an interface with the third-party introspection that requires an http response code of 200 and a JSON element named `active` with the value `true`. In the code, the key part is `var response = { "active": true };` and `apim.setvariable('message.status.code', 200);`. Read the code to understand the input to the request and the expected response. This code does not perform any token validation, it accept any access token, but it can easily be modified to call an third-party OAuth provider via the `url-open` function. 
3. Open the API designer and select the `utility` API. This API will simulate the third-party introspection lookup (it uses the `introspect.js` code). 
4. Click the **Assemble** tab and select the `switch` statement with the condition `/third-party-oauth/introspect` and its corresponding GatewayScript. Its the same code you just examined. If you made any changes, you can copy the code from `introspect.js` and paste it here or leave it as-is.
5. Protect API with Introspection lookup
	* Open the **Weather Provider API** and scroll down to **Security Definitions**. Click the + button and select **OAuth**.
	* Enter the name `oauth-third-party`. In the **Introspection URL** field, enter `https://127.0.0.1:9443/utility/third-party-oauth/introspect`. Leave the remaining fields at their default values.
	* In the **Security** section, create a new security requirement (click +) and select  **api-key-1 (API Key)** and  **oauth-third-party (OAuth)**. Click the up array to move it as **Option 1**.
	* Click Save.

	![alt](images/introspect_url.png)
	
6. Obtain an access token from the Third-Party OAuth provider (using the resource owner grant type) using Postman.
	* Open the request called `OAuth Password`. Select the **Body** link and notice that a default client id of `default` and client secret of `SECRET` is pre-configured. Adjust the values of your endpoint to `https://127.0.0.1:4001/third-party/oauth2/token`.
	* Submit the request and validate that you get back an access token.
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
7. Open the Weather request and select the **Headers** tab. Click **Send** to validate that the request is successful. Optionally, enter the previously copied access token into the Authorization header field if you don't want to use the variable `{{access_code}}`.
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
8. Verify that the simulated introspection endpoint is invoked by looking at the system logs. Using the Web browser, open the DataPower Web GUI (https://localhost:<port>), where port is obtained from `docker ps` and the port mapping (`0.0.0.0:32773->9090/tcp`). For example, the Web GUI will be available at https://localhost:32773/. Click the Hamburger icon in the top-left hand corner and select **Logs**. Make sure you see the log message generated in the `utility` service.
	```
	mpgw (webapi): >> oauth introspection - returning response {"active":true,"scope":"spoon fork knief","basic-authorization":"Basic ZGVmYXVsdDpTRUNSRVQ=","input_body":"token=AAEHZGVmYXVsdC3_ZlWBeAfAegONOvAFldQTeTxZMsDhZVYM_JSp99gZwGF_y3ZsvJ_DtRdsEj84Ls2QROnqRM1Grf8RmTVThssgnWlw4ZQYqRKH1JN0SjZoFQBpgrmzYnbNVA5cUsrf4jNyLPS9-4MLtzsdyXLQcZ5udgWQCGEeYOnUMCCeEvSHwvbtGyPjltafPGCBM1PFrlXrWQEn2kgSygRN6-s9RjBY2ypc-hoQy99Pcv73gIKOCIJCpo28fgeAmKdNqrMJAFnb7IirRZt-JZTeV0to7L1KaeZ3yfipDzs5ObtHjgRrMMn63gwtx5L2AhDhiYUy6g&token_type_hint=access_token"}
	```

**Bonus**

The utility service was used to simulate the introspection endpoint, so you could see the data on the wire but you could have easily used the introspection endpoint within the `third-party OAuth provider` (which happens to be API Connect!). In the Weather API, change the Introspection URL to `https://127.0.0.1:9443/third-party/oauth2/introspect` and make sure you get back the correct response. 

In this tutorial, you learned how to validate an access token generated from a third-party OAuth provider using the introspection lookup feature. It allows API Connect to enforce access to APIs using access tokens generated outside of API Connect, enabling you to maintain your investment in existing Identity and Access Management (IAM) solutions whilst leveraging the full capabilities of an API Connect platform.

**Next Tutorial**: [Protect APIs with OAuth using external authentication service](../master/oauth-redirect/README.md)