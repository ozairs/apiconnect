# Manage digital applications with OAuth lifecycle management

**Authors** 
* [Ozair Sheikh](https://github.com/ozairs)

Special thanks to [Shiu-Fun Poon](https://github.com/shiup) for the API assets and knowledge transfer. 

**Prequisites**

* [API Connect Developer Toolkit 5.0.7.1](https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.toolkit.doc/tapim_cli_install.html)
* For testing, you will need to download [Postman](https://www.getpostman.com/).
* Download the Postman collection [here](https://www.getpostman.com/collections/9ab248322bd2f0a75eea)

For more information on setting up OAuth, see the article [here](https://www.ibm.com/support/knowledgecenter/en/SSFS6T/com.ibm.apic.toolkit.doc/tutorial_apionprem_security_OAuth.html).

**Instructions:** 

* **Note:** If you did not complete previous tutorial, import API definitions file: oauth, utility and Weather. Click the **Add (+)** button and select **Import API from a file or URL**. 
	* [https://raw.githubusercontent.com/ozairs/apiconnect/master/oauth/weather-provider-api_1.0.0.yaml]() 
	* [https://raw.githubusercontent.com/ozairs/apiconnect/master/oauth/oauth_1.0.0.yaml](). 
	* [https://raw.githubusercontent.com/ozairs/apiconnect/master/oauth/utility_1.0.0.yaml](). 

In this tutorial, you will learn how to obtain a new access token from a refresh token, revoke tokens, and obtain token details using OAuth introspection.

The Postman collection includes helpful OAuth requests, lets test each of them to understand the OAuth capabilities.

1. Use the **OAuth Password** request to obtain an access token. 
	```
	{
		"token_type": "bearer",
		"access_token": "<sanitized>",
		"expires_in": 3600,
		"scope": "weather",
		"refresh_token": "<sanitized>"
	}
	```
2. Use the **OAuth Token List** to obtain a list of tokens from an OAuth application (ie `client_id=default`). Slick **Send** to view the list of tokens. It will return the previously obtained access token.
	```
	[
		{
			"clientId": "default",
			"clientName": "default",
			"owner": "cn=spoon,email=spoon@poon.com",
			"scope": "weather",
			"issuedAt": 1495268682,
			"expiredAt": 1497950682,
			"refreshTokenIssued": true
		}
	]
	```
3. Use the **OAuth App Revocation** to remove all access tokens issued to an OAuth application - `client_id=default`. Click **Send** to revoke all access tokens for the application `default`.
	```
	{
		"status": "success"
	}
	```
4. Invoke the **OAuth Token List** request now. You won't get any tokens returned since the tokens are revoked.
	```
	[]
	```
5. Use the **OAuth Refresh Token** request to obtain a new access token when an access token is expired without going through the OAuth handshake again. Submit the **OAuth Password** request again.

6. Open the **OAuth Refresh Token** request and paste the refresh token into the existing field within the *Body*. This will return both a new access token and refresh token.
	```
	{
	"token_type": "bearer",
	"access_token": "<sanitized>",
	"expires_in": 3600,
	"scope": "weather",
	"refresh_token": "<sanitized>"
	}
	```
6. In the same **OAuth Refresh Token** request, click **Send** again to get a new access token from the refresh token. You will get an error because the old refresh token is invalidated when a new access token is returned from a refresh token.
	```
	{
		"error": "invalid_grant"
	}
	```
7. The **OAuth Introspection** request validates the access token and returns the details of the access token. Obtain a valid access token using any of the previous requests and copy the token into the `token` field within the **Body**. Click **Send** to obtain the details:
	```
	{
	"active": true,
	"token_type": "bearer",
	"client_id": "default",
	"username": "cn=spoon,email=spoon@poon.com",
	"sub": "cn=spoon,email=spoon@poon.com",
	"exp": 1495273141,
	"expstr": "2017-05-20T09:39:01Z",
	"iat": 1495269541,
	"nbf": 1495269541,
	"nbfstr": "2017-05-20T08:39:01Z",
	"scope": "weather",
	"miscinfo": "[r:gateway]",
	"client_name": "default"
	}
	```
8. Optionally, revoke the token using the **Single Token Revocation** request and then issue the **OAuth Introspection** call again, you will get an error because the token is not valid.
	```
	{
	"active": false
	}
	```
	
In this tutorial, you learned about the lifecycle of OAuth tokens. Specifically, you obtained a new access token from a refresh token. Revoked and listed tokens and obtained the details of an access token.

**Next Tutorial**: [Enforce API access with Third-party OAuth providers](../master/oauth-third-party/README.md)