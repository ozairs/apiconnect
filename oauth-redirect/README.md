# Protect APIs with OAuth using external authentication service

**Authors** 
* [Ozair Sheikh](https://github.com/ozairs)

Special thanks to [Shiu-Fun Poon](https://github.com/shiup) for the API assets and knowledge transfer. 

**Prerequisites:** 

* For testing, you will to download [Postman](https://www.getpostman.com/). 
* Download the Postman collection [here](https://www.getpostman.com/collections/951c78382a60b7f7be67)

**Instructions:** 

API Connect supports multiple approaches to authenticate / authorize identities (ie resource owners) during the OAuth handshake. It allows you to use HTTP Basic Auth or forms (gateway hosted custom or built-in HTML forms); however, many enterprises have already created their own authentication service on an externally hosted server. Typically, the authentication service has already been branded with the enterprise look-and-feel and is deployed as a Web application, so moving it to th gateway will be problematic.

Fortunately, API Connect provides the ability to use an externally hosted authentication service to authenticate and authorize the identity and then allow API Connect to generate the access token (and authorization code) once its been successful. For simplicity, we will call it the `redirect` capability. In comparison with the third-party OAuth provider integration, using the `redirect` feature still uses API Connect built-in OAuth provider and so it will provides complete OAuth authorization server capabilities, such as grant validation, identity extraction, authentication, authorization, token management, introspection, and more. 

The redirect as the name implies will actually redirect the user agent (ie Web browser) to an externally hosted authentication service. If the OAuth endpoint is `https:<api-connect-endpoint>\oauth2\authorize` in the Web browser, after the redirect, it will become `https:<third-party-auth-service>\login.html`. The identity extraction, authentication and authorization will occur outside of API Connect. Once the authentication service has successfully authenticated / authorized the user, it will need to `callback` into API Connect. This `callback` is a contract between API Connect and the third-party authentication service. Here is the high-level flow:
	1. API Connect will perform a redirect to the third-party authentication service and populate the URL with the following information
		* original-url
		* app-name
		* appid
		* org
		* orgid
		* catalog
		* catalogid
		* provider
		* providerid
	2. Third-party authentication service will need to issue a HTTP 302 request with the `Location` header containing the following: 
		```
		origUrl + '&username=' + username + '&confirmation=' + confirmationCode
		``` 
		The **username** is the `authenticated credential value` and the **confirmation code** is any string that can be verified by the third-party authentication service. The **original URL** is provided to the service during the initial redirection from API Connect, so it will need to track it when calling back into API Connect.
	3. API Connect will extract the confirmation code from the callback URL and validate the *confirmation code* against the third-party authentication service validation endpoint. As long as the endpoint responds back with an HTTP response code of 200, then the code is deemed valid. It's discarded for the remainder of the flow since API Connect will generate its own access token as part of the overall OAuth flow.

	Below is a diagram with a sequence diagram of the overall flow:

	![alt](images/redirect_flow.jpg)

For more information on setting up OAuth redirect, see the article [here](https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.toolkit.doc/task_apionprem_redirect_form_.html).

1. Import API definitions file: oauth, utility and Weather. Click the **Add (+)** button and select **Import API from a file or URL**. 
	* [https://raw.githubusercontent.com/ozairs/apiconnect/master/oauth-redirect/weather-provider-api_1.0.0.yaml]() 
	* [https://raw.githubusercontent.com/ozairs/apiconnect/master/oauth-redirect/oauth_1.0.0.yaml](). 
	* [https://raw.githubusercontent.com/ozairs/apiconnect/master/oauth-redirect/utility_1.0.0.yaml]().
	* [https://raw.githubusercontent.com/ozairs/apiconnect/master/oauth-redirect/oauth-redirect_1.0.0.yaml]().  

	In this tutorial, we will simulate the external third-party authentication service using the `utility` API, which is API Connect hosted Assembly that will parse the input and return back the appropriate response.

2. Navigate to the folder `https://github.com/ozairs/apiconnect/blob/master/utility/redirect` directory and open the `redirect.js` file. This file will simulate the third-party authentication service. A few points about the code:
	* `console.error` will write the input parameters into the logs. We use log level error since its the default configuration but you likely want to log at a lower level such as info or debug.
	* No actual authentication / authorization is performed in the script, we simply hardcode a username and confirmation code. The values are setup in the API assembly `set-variable` action.
	* Build the URL string and the 302 response code
3. Once API Connect parses the URL, it will then verify the confirmation code and username by sending it to the endpoint configured in `authentication url`. This will be the same Utility API, specifically the code in `redirect-authenticate.js` (in the same directory). Read through the comments in the code. The key line is `apim.setvariable('message.status.code', 200);` which returns a 200 response code. If you need to include additional information as part of the access token, scope or payload, then you can include additional response headers as per the code.
4. Open the API designer and select the `utility` API. This API will simulate the third-party authentication service. 
5. Click the **Assemble** tab and select the `switch` statement with the condition `/identity-extract/redirect` and its corresponding GatewayScript. You can modify the code from `redirect.js` and copy it here or leave it as-is.
6. Select the `switch` statement with the condition `/identity-extract/redirect/authenticate` and its corresponding GatewayScript. You can modify the code from `redirect-authenticate.js` and copy it here or leave it as-is.
7. Configure the OAuth2 Provider (Redirect) to use the third-party authentication service.
	* Scroll down to **Identity Extraction** and enter the Redirect URL for the redirect utility service, `https://127.0.0.1:4001/utility/identity-extract/redirect`. Note that in a real-world scenario, it would use a non-API Connect hostname. We are using port 4001 since the Web browser is performing a redirect and it only has access to Docker exposed ports.
	* Under **Authentication**, enter the URL `https://127.0.0.1:9443/utility/identity-extract/redirect`
	* Under **Authorization**, leave the default `Authenticated` since the authorization will be performed by the third-party authentication service.
8. Obtain an access token from the OAuth provider (redirect) by entering the following URL into a Web browser `https://127.0.0.1:4001/redirect/oauth2/authorize?scope=weather&response_type=code&client_id=default&redirect_uri=https://www.getpostman.com/oauth2/callback`.
9. The Web browser should perform a couple of redirects and the result should contain the following URL: `https://app.getpostman.com/oauth2/callback?code=<code>` where <code> is a sequence of characters. The hostname in the browser is the `redirect-uri` that you entered in the original request, and its typically your OAuth application that will exchange the code for an access token. Since our Postman test tool is not configured to exchange authorization codes for access token, we will manually perform that step.
10. Copy the `code` after `code=` so it remains on your clipboard.
11. Open the `OAuth Code to Token` request and click the **Body** tab. Paste the code value into the `code` field. Click **Send** and verify you receive an access token.
12. Submit the request and validate that you get back an access token.
	```
	{
		"token_type": "bearer",
		"access_token": "<sanitized>",
		"expires_in": 3600,
		"scope": "weather",
		"refresh_token": "<sanitized>"
	}
	```
13. Copy the access token so it remains on your clipboard. You are now ready to call the Weather API!
14. Open the Weather request and select the **Headers** tab. Click **Send** to validate that the request is successful. Optionally, enter the previously copied access token into the Authorization header field if you don't want to use the variable `{{access_code}}`.
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
15. Verify that the simulated redirect authentication service by looking at the system logs. Using the Web browser, open the DataPower Web GUI (https://localhost:<port>), where port is obtained from `docker ps` and the port mapping (`0.0.0.0:32773->9090/tcp`). For example, the Web GUI will be available at https://localhost:32773/. Click the Hamburger icon in the top-left hand corner and select **Logs**. Make sure you see the log message generated in the `utility` service.
	```
	mpgw (webapi): original-url : 'https%3A%2F%2F192.168.0.16%3A4001%2Fredirect%2Foauth2%2Fauthorize%3Fscope%3Dweather%26response_type%3Dcode%26client_id%3Ddefault%26redirect_uri%3Dhttps%3A%2F%2Fwww.getpostman.com%2Foauth2%2Fcallback%26rstate%3DB12bFwvS1O-mbitJbBojcLLSNNbAuiJLSQHxY275reI'



	mpgw (webapi): redirect back to apic [ 'https://192.168.0.16:4001/redirect/oauth2/authorize?scope=weather&response_type=code&client_id=default&redirect_uri=https://www.getpostman.com/oauth2/callback&rstate=B12bFwvS1O-mbitJbBojcLLSNNbAuiJLSQHxY275reI&username=spoon&confirmation=ozair' ']'
	```

In this tutorial, you learned how to perform authentication / authorization of a user identity using an external third-party authentication service. Specifically, you learned about the interface between the third-party and API connect. This feature allows you to reuse existing identify access management solutions when enforcing access to API resources.

**Next Tutorial**: [Restrict access to critical resources with OAuth scope check](../master/scope/README.md)