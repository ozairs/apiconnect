# Restrict access to critical resources with OAuth scope check

**Authors** 
* [Ozair Sheikh](https://github.com/ozairs)

Special thanks to [Shiu-Fun Poon](https://github.com/shiup) for the API assets and knowledge transfer. 

**Prerequisites:** 

* For testing, you will to download [Postman](https://www.getpostman.com/). 
* Download the Postman collection [here](https://www.getpostman.com/collections/9ab248322bd2f0a75eea)

**Instructions:** 

**What is OAuth scope?**

A scope is a string that is used to identify the resources granted access within an OAuth access token. The meaning of the scope is dependent upon the resource provider. For example, common scopes may include strings such as read and write. If a read scope is issued to an access token but the API operation performs a write operation, then the resource provider will reject the request.

**What is Advance Scope Check?**

OAuth clients will present scopes to the OAuth server (as per the OpenAPI definition) and validate the resource owner credentials and obtain consent before issuing an access token with the scopes. In a regular scenario, what you ask for is what you get. If I requested a `savings` scope, then I would get a savings scope in my access token. In the Advance scope check scenario, I could request a savings scope but get a `savings-premium` scope based on my account status. This capability allows the OAuth server to constrain access to the resources via scopes with little complexity. Furthermore, consider that if you decided to list every single savings account, it would become quite complicated; instead, you provide a generic scope and using the Advance scope check, you can issue the actual scope to the application.

**Advance Scope check configuration within API Connect**

The Advance scope check is a toggle that is available in the OAuth2 provider configuration. You specify a URL to a service that returns a new scope via a response header `x-selected-scope`. This step is performed before issuing the access token.


1. Import API definitions file: oauth, utility and Weather. Click the **Add (+)** button and select **Import API from a file or URL**. 
	* [https://raw.githubusercontent.com/ozairs/apiconnect/master/scope/weather-provider-api_1.0.0.yaml]() 
	* [https://raw.githubusercontent.com/ozairs/apiconnect/master/scope/oauth_1.0.0.yaml](). 
	* [https://raw.githubusercontent.com/ozairs/apiconnect/master/scope/utility_1.0.0.yaml](). 

	In this tutorial, we will simulate the external scope service using the `utility` API, which is API Connected hosted Assembly that will parse the input and return back the appropriate response.

2. Navigate to the folder `https://github.com/ozairs/apiconnect/blob/master/utility/scope` directory and open the `provider-scope-check.js` file. This file will simulate the scope service. It simply creates a response header `x-selected-scope`, which tells API connect the new scope value to use (together with an HTTP response code of 200).
3. Open the API designer and select the `utility` API. This API will simulate a scope service. 
4. Click the **Assemble** tab and select the `switch` statement with the condition `/api/scope-check` and its corresponding GatewayScript. You can modify the code from `provider-scope-check.js` and copy it here or leave it as-is.
6. Configure the OAuth2 OIDC Provider to use the advance scope service and change the `weather` scope to `weather toronto`. Scroll down to **Advance Scope Check** and enter the URL for the advance scope service, `https://127.0.0.1:9443/utility/api/scope-check`.
6. Obtain an access token from the OAuth provider (using the resource owner grant type) using Postman.
	* Open the request called `OAuth Password`. Select the **Body** link and notice that a default client id of `default` and client secret of `SECRET` is pre-configured.
	* Submit the request and validate that you get back an access token with a new scope of `weather California`.
	```
	{
		"token_type": "bearer",
		"access_token": "<sanitized>",
		"expires_in": 3600,
		"scope": "weather california",
		"refresh_token": "<sanitized>"
	}
	```
	* Optionally, copy the access token so it remains on your clipboard. You are now ready to call the Weather API!
7. Open the Weather request and select the **Headers** tab. Click **Send** to validate that the request is successful.
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

In this tutorial, you learned how to enforce stricter access controls based on scope. API Connect OAuth provider can modify scope values either for every request. This capability allow more granular controls of permissions when accessing API resources.

**Next Tutorial**: [Protect access to Open Banking APIs using OpenID Connect](../master/openbanking/README.md)
