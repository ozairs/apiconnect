# Manage API Authentication lifecycle for enhanced user experience

In this tutorial, you will learn about the various OAuth token lifecycle operations. Specifically, you will learn how to obtain a new access token from a refresh token, revoke tokens, and obtain token details using OAuth introspection.

**What is OAuth lifecycle management?**

Web site / Mobile application that provide access to third-party API services (ie login with your Google credentials) using OAuth will store your 'permission' so they don't need to re-ask your permissions again. It will allow you to login to your favourite application (ie using your google credentials) without being prompted again to perform the OAuth handshake.

Each OAuth token has a validity date and can expire. For mobile applications, they often provide long-lived sessions so you don't need to login to the application everytime you open it. For these use cases, a refresh token provides a convenient way to obtain a new access token for an expired access token without performing the OAuth handshake again. In other circumstances, you may want to remove your previous consented permissions (ie login with Google) or you may have lost your mobile device and want to remove the permissions to avoid unauthorized access. In these situtations, you can revoke your permissions granted to an OAuth application to prevent the OAuth application from accessing your resources.

These capabilities are critical to providing a first-class application experience because things can go wrong but the user experience does not have to suffer along the way. In his article, you will learn about the various OAuth token lifecycle capabilite and how to build them into your application.

**Prerequisites**

* [API Connect Developer Toolkit 5.0.7+](https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.toolkit.doc/tapim_cli_install.html)
* Import API definitions file: oauth, utility and Weather. Click the **Add (+)** button and select **Import API from a file or URL**. 
	* [https://github.com/ozairs/apiconnect/blob/master/oauth/weather-provider-api_1.0.0.yaml]() 
	* [https://github.com/ozairs/apiconnect/blob/master/oauth/oauth_1.0.0.yaml](). 
	* [https://github.com/ozairs/apiconnect/blob/master/oauth/utility_1.0.0.yaml](). 
* [Postman](https://www.getpostman.com/).
* Download the Postman collection [here](https://www.getpostman.com/collections/951c78382a60b7f7be67)

**Important:**

If your unfamiliar with running the API Connect Developer toolkit, you can follow the instructions [here](https://github.com/ozairs/apiconnect/blob/master/getting-started/README.md).

**Instructions:** 

The API definitions contain pre-configured OAuth configuration. You will use the Postman collection to run requests and learn about the various OAuth token lifecycle operations.

If you want to learn about OAuth configuration, see [here](https://www.ibm.com/support/knowledgecenter/en/SSFS6T/com.ibm.apic.toolkit.doc/tutorial_apionprem_security_OAuth.html)

Let's first get an access token using the OAuth resource owner grant type. Change the hostname/port number in the Postman requests if they are different in your environment.

1. Using the Postman collection, open the **OAuth Password** request and click **Send**.
	```
	{
		"token_type": "bearer",
		"access_token": "<sanitized>",
		"expires_in": 3600,
		"scope": "weather",
		"refresh_token": "<sanitized>"
	}
	```
2. Use the **OAuth Token List** request to obtain a list of tokens from an OAuth application (ie `client_id=default`). Click **Send** to view the list of tokens. It will return the previously obtained access token.
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
3. Use the **OAuth App Revocation** request to remove all access tokens issued to an OAuth application (ie `client_id=default`). Click **Send** to revoke all access tokens for the application `default`.
	```
	{
		"status": "success"
	}
	```
4. Invoke the **OAuth Token List** request now. You won't get any tokens returned since the tokens are revoked.
	```
	[]
	```
5. Use the **OAuth Refresh Token** request to obtain a new access token when an access token is expired without going through the OAuth handshake again. If you still have the  **OAuth Password** response open, copy the refresh token onto your clipboard (otherwise submit the **OAuth Password** request again to obtain a new access token and copy the refresh token to your clipboard). 

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
7. The **OAuth Introspection** request validates the access token and returns the details of the access token. Use the **OAuth Password** request again to obtain a new access token. In the **OAuth Introspection** request, copy the access token into the `token` field within the **Body**. Click **Send** to obtain the details:
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
8. Optionally, revoke the token using the **OAuth App Revocation** request and then issue the **OAuth Introspection** call again, you will get an error because the token is not valid.
	```
	{
	"active": false
	}
	```
	
In this tutorial, you learned about the lifecycle of OAuth tokens. Specifically, you obtained a new access token from a refresh token. Revoked and listed tokens and obtained the details of an access token.