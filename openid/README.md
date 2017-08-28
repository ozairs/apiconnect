## Protect access to APIs using OpenID Connect

In this tutorial, you will protect access to your APIs using [OpenID Connect](http://openid.net/connect/).

**What is OpenID Connect?**

OpenID Connect (OIDC) is built on top of the OAuth 2.0 protocol and focuses on identity assertion. OIDC provides a flexible framework for identity providers to validate and assert user identities for Single Sign-On (SSO) to web, mobile, and API workloads. This capability helps address authentication and authorization requirements for Payment Services Directive 2 (PSD2) and Open Banking.

**Duration**: 30 minutes

**Skill level**: Intermediate

**Prerequisites:** 
* [API Connect Developer Toolkit 5.0.7.1](https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.toolkit.doc/tapim_cli_install.html)
* API Connect on [Bluemix](https://bluemix.net) account
* For testing, you will need [Postman](https://www.getpostman.com/).

OpenID Connect uses the same OAuth grant types (implicit, password, application and access code) but uses OpenID Connect specific scopes, such as `openid` with optional scopes to obtain the identity, such as `email` and `profile`. OpenID Connect generates a JWT token (instead of an opaque token with OAuth), which can be optionally signed and encrypted. 

API Connect fully supports JSON Web Encryption (JWE) and JSON Web Signature (JWS) either with OpenID Connect or standalone use cases.

**Important**

The steps below require an API manager installation to publish API definitions. It can be deployed on your infrastructure or via Bluemix. The following steps obtain information needed for this tutorial.

* Login to the API manager with your credentials (email/password). 
* In the **Dashboard** page, click the **Sandbox** catalog and then click the wheel icon to open **Settings** page.
* In **Overview**, the **Automatic subscription** toggle should already be selected. Click the **Show** button to note the client ID and client secret. For example, client id is `d03c438a-2010-4f21-8520-c111a86a9f16` and client secret is `d03c438a-2010-4f21-8520-c111a86a9f16`.
* Select **Gateways** and make a note of the URL, such as `https://hostname/om/sb`.
* Select **Portal** and make a note of the Portal URL. Go ahead and create an account in the portal.

The following items will be referenced below:
* Client ID: d03c438a-2010-4f21-8520-c111a86a9f16 (example)
* Client Secret: d03c438a-2010-4f21-8520-c111a86a9f16 (example)
* Gateway Endpoint: https://hostname/om/sb
* Developer Portal: https://hostname

**Instructions:** 

These instructions assume your familiar with the basic steps of the API designer. You will import the OAuth provider YAML file which provides support for OIDC connect. We will review it first to understand the core functions.

1. Using the command prompt, create a directory for your project and open the API designer.
	```
	mkdir apic-workspace
	cd apic-workspace
	apic edit
	```
2. In the **APIs** tab, click the **Add (+)** button and select **Import API from a file or URL**.
3. Click **Import from URL ...** and enter **https://raw.githubusercontent.com/ozairs/apiconnect/master/openid/utility_1.0.0.yaml**. Click **Import** to finish the task.
4. Repeat the steps to import the API definitions file from here:
 * **https://raw.githubusercontent.com/ozairs/apiconnect/master/openid/weather-provider-api_1.0.0.yaml**
 * **https://raw.githubusercontent.com/ozairs/apiconnect/master/openid/oauth_1.0.0.yaml**.
5. APIs to to be grouped together for deployment to API Connect on Bluemix. Packaging is done using a products, which provides packaging of one or more APIs into a single group that is a deployable unit and enables enforcement of rate limit definitions.
6. Select the Products tab and click Add + -> New Product.
7. Enter the name weather and click Create product.
8. Click the recently created product and select APIs (in the left nav bar).
9. Click the + button to add the following APIs
	* OAuth2 OIDC Provider
	* Weather Provider API
	* utility
10. Click Apply when complete.
11. Click the **OAuth 2 OIDC Provider 1.0.0** API and examine the following parts the OAuth Provider API:
	* **Paths**: Token API exposed on paths `/oauth2/authorize` and `/oauth2/token`. The path `/oauth2/introspect` allow you to obtain information about the access token.
	* **OAuth 2**: The default grant types supported, but more important are the scopes available. The scope `openid` triggers the OpenID Connect flow and the scope `weather` is the consumer resource. Add additional scopes for your applications here.
	* **Authentication URL**: the resource owner is authenticated using the endpoint `https://127.0.0.1/utility/basic-auth/spoon/spoon`. This is a mock service in the **utility_1.0.0.yaml** that returns the authenticated credential in JSON format. The format is https://127.0.0.1/utility/basic-auth/{username}/{password}.  Replace `spoon/spoon` with another value if you want to use a different set of username and password. 
12. The example assumes that the utility service is hosted on the same gateway. Change the Authentication URL from `https://127.0.0.1/utility/basic-auth/spoon/spoon` to `https://hostname/om/sb/utility/basic-auth/spoon/spoon`.
13. Click the **Assemble** tab at the top. You will notice several policies that control the generation of the JWT token for OIDC flows. The `set-variable` and `jwt-generate` can be customized if you need to provide custom claims and other JWT information.
	You will now publish the API definitions to Bluemix. If your using your own API manager stack, you will need to follow select the non-Bluemix option.
14. Make sure you have saved your APIs. Click the Save icon in the right-hand corner.
15. Click the **Publish** button in the nav bar.
16. Click **Add IBM Bluemix** target, and sign-in with your credentials.
17. The **Sandbox** catalog provisioned will be shown. Make sure its selected and click **Save**.
18. Click the **Publish** button (leave the defaults unchecked) and make sure you get a successful publish message. You are now ready for testing.
  

1. Open the Weather API and test the unprotected (ie no security) APIs `/current` and `/today` using `curl`. Modify the `x-ibm-client-id` and `x-ibm-client-secret` values. Modify your endpoints below in the command.
	```
	$ curl https://hostname/om/sb/current?zipcode=90210 -H "X-IBM-Client-Id: default" -k
	{"zip":"90210","temperature":62,"humidity":90,"city":"Beverly Hills","state":"California","platform":"Powered by IBM API Connect"}

	$ curl https://hostname/om/sb/today?zipcode=90210 -H "X-IBM-Client-Id: default" -k
	{"zip":"90210","hi":72,"lo":56,"nightHumidity":91,"city":"Beverly Hills","state":"California","dayHumidity":67}
	```
2. Protect Weather API with OpenID Connect
	Modify the security definition of the Weather API (ie consumer API) to protect access using the OAuth 2 OIDC Provider. It will require consumer applications to obtain an access token before invoking the Weather API.
	* Open the **Weather Provider API** and scroll down to **Security Definitions**. Click the + button and select **OAuth**.
	* Enter the name `openid-password` and select the **Password** flow. Enter the **Token URL** value `https://hostname/om/sb/oauth2/token` (using the OAuth provider API imported earlier deployed on the same Gateway).
	* Scroll down to the scopes section and enter the scopes `weather` and `openid`.
	* In the **Security** section, select **openid-password (OAuth)** and the two scopes.
	* Save the API definition.
	* Click the **Publish** button in the nav bar to push the changes to Bluemix.

3. Test the same Weather APIs `/current` and `/today`, you will now get an error because the API is protected using OAuth. In the next step you will obtain an access token to call the same APIs
	```
	curl https://hostname/om/sb/today?zipcode=90210 -H "X-IBM-Client-Id: default" -k
	{ "httpCode":"401", "httpMessage":"", "moreInformation":"This server could not verify that you are authorized to access the URL" }
	```
4. Obtain an access token from the OIDC provider (using the resource owner grant type). Invoking OAuth APIs can be tricky because you need to have the appropriate parameters, so we have provided a Postman collection to simplify testing.
	* Open Postman and select **File -> Import -> Import from Link** and enter the value https://www.getpostman.com/collections/951c78382a60b7f7be67.
	* Open the request called `OIDC Password`. Select the **Body** link and notice that a default client id of `default` and client secret of `SECRET` is pre-configured. Modify these values with the client Id and client Secret obtained earlier. Adjust the endpoint with your gateway hostname ie `https://hostname/om/sb/oauth2/token`.
	* Submit the request and validate that you get back an access token and id token (JWT).
	```
	{
		"token_type": "bearer",
		"access_token": "<sanitized>",
		"expires_in": 3600,
		"scope": "weather openid",
		"refresh_token": "<sanitized>",
		"id_token": "<sanitized>"
	}
	```
	* Copy the access token so it remains on your clipboard. You are now ready to call the Weather API!
5. Open the weather request and select the **Headers** tab. Enter the previously copied access token into the Authorization header field. Modify the `x-ibm-client-id` and `x-ibm-client-secret` values. Change the endpoint address and click **Send** to validate that the request is successful.
	```
	{
		"zip": "90210",
		"temperature": 64,
		"humidity": 84,
		"city": "Beverly Hills",
		"state": "California",
		"platform": "Powered by IBM API Connect"
	}
	```

You successfully obtained an **access token** and **id token** using the resource owner grant type. Only the **access token** is needed to access the weather API, so your probably curious about the **id token**. OpenID Connect still uses the **access token** to enforce access to APIs (similar to OAuth) but it adds an **id token**, which provides additional details about the user identity and claims (name-value pairs) that the OAuth application can use to personalize the user experience or store additional metadata about the user. We will examine this token more at the end of the tutorial.

The resource owner grant type should only be used for trusted OAuth applications since the username and password are shared between the resource owner and OAuth application. Most often you will use the Access Code flow (ie authorization code grant) since it protects the username and password from the OAuth application and still enables sharing of resources to the OAuth application. In the next step, you will setup an Access Code flow.

When using the API Connect developer toolkit with OAuth Access code flow, you will need to redirect the application to an OAuth client to exchange the authorization code for an access code. This is typically done in an OAuth application, but we can use a couple of techniques to streamline testing.

1. Create a new application within the developer portal and register a redirect URI with the value `https://www.getpostman.com/oauth2/callback`.
	* See instructions [here]()https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.devportal.doc/task_cmsportal_registerapps.html. You will need to create a new account if you have not registered previously.
	**Note**: Use the client_id and client_secret credentails from the dev portal test app instead of the values obtained in the previous section (ie Automatic Subscription).
2. Open Postman Preferences and disable **Automatically follow redirects**.
	![alt](media/postman.png)

3. Protect Weather API with OpenID Connect Access Code flow  
	* Open the **Weather Provider API** and scroll down to **Security Definitions**. Click the + button and select **OAuth**.
	* Enter the name `openid-accesscode` and select the **Access Code** flow. Enter the **Authorize URL** value `https://hostname/om/sb/oauth2/authorize` and **Token URL** value `https://hostname/om/sb/oauth2/token` (change the hostname to reflect your environment).
	* Scroll down to the scopes section and enter the scopes `weather` and `openid`.
	* In the **Security** section, click the + button to create a new option and select **openid-accesscode (OAuth)** and the two scopes.
	* Save the API definition.
	* Click the **Publish** button in the nav bar to push the changes to Bluemix.	
	**Note:** Multiple security definitions allow you provide multiple options to satisfy consumer security requirements.
	
	![alt](media/security-oidc.png)

3. Open the request called `OIDC Access Code`. Adjust the values for your endpoint to `https://hostname/om/sb/oauth2/token`. Change the `client_id` in the **Body** tab.
	* Submit the request and make sure you get the following response:
	```
	<?xml version="1.0" encoding="UTF-8"?>
	<html>
		<body>Go ahead</body>
	</html>
	```
	The Access Code flow requires an additional step to obtain an access token. You will need to exchange the code for an access token. This is typically done by an OAuth application but you will simulate one for simplicity.
	* Click the **Headers** tab and copy the value after `code=`
	* Open the `OAuth AC to Token` request and click the **Body** tab. Paste the code value into the `code` field. Change the endpoint to `https://hostname/om/sb/oauth2/token`. Change the `client_id` and `client_secret` in the **Body** tab. Click **Send** and verify you receive an access token
4. Open the Weather request and select the **Headers** tab. Enter the previously copied access token into the Authorization header after the `Bearer` string. Modify the  and click **Send**. Validate that the request is successful.
	```
	{
		"zip": "90210",
		"temperature": 64,
		"humidity": 84,
		"city": "Beverly Hills",
		"state": "California",
		"platform": "Powered by IBM API Connect"
	}
	```
	All the test cases till now have focused on accessing the API using an OAuth access token although an JWT token (via `id_token` field) is also returned. The JWT token allows the OAuth application access to information about the user identity.

5. Open the Web site [jwt.io](https://jwt.io). Copy/paste the id_token value into the **Encoded** textbox, which should then display the decoded token

	![alt](media/view-jwt.png)

The fields within the JWT token can be customized based on your environment. The OAuth provider Assembly provides the flexibility to generate a JWT token and optionally sign and encrypt it.

In this tutorial, you learned how to protect an API using OpenID Connect resource owner and access code flow.