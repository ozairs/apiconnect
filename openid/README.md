## Protect access to APIs using OpenID Connect

In this tutorial, you will protect access to your APIs using [OpenID Connect](http://openid.net/connect/).

**What is OpenID Connect?**

OpenID Connect (OIDC) is built on top of the OAuth 2.0 protocol and focuses on identity assertion. OIDC provides a flexible framework for identity providers to validate and assert user identities for Single Sign-On (SSO) to web, mobile, and API workloads. This capability helps address authentication and authorization requirements for Payment Services Directive 2 (PSD2) and Open Banking.

**Authors** 
* [Shiu-Fun Poon](https://github.com/shiup)
* [Ozair Sheikh](https://github.com/ozairs)

**Duration**: 15 minutes

**Skill level**: Intermediate

**Prerequisites:** 

* [API Connect Developer Toolkit 5.0.7.1](https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.toolkit.doc/tapim_cli_install.html)
* For testing, you will need [Postman](https://www.getpostman.com/).

OpenID Connect uses the same OAuth grant types (implicit, password, application and access code) but uses OpenID Connect specific scopes, such as `openid` with optional scopes to obtain the identity, such as `email` and `profile`. OpenID Connect generates a JWT token (instead of an opaque token with OAuth), which can be optionally signed and encrypted. 

API Connect fully supports JSON Web Encryption (JWE) and JSON Web Signature (JWS) either with OpenID Connect or standalone use cases.

**Important:** 

The latest API Connect Developer toolkit has a bug that requires a patch. Let's execute the following instructions:

1. Download the following files to your machine and save it to a known location:
	* https://raw.githubusercontent.com/ozairs/apiconnect/master/openid/patch/sts-oauth-post-aaa-2.xsl
	* https://raw.githubusercontent.com/ozairs/apiconnect/master/openid/patch/aaa-basic-au.xsl
	* https://raw.githubusercontent.com/ozairs/apiconnect/master/openid/patch/aaa-oauth-au.xsl
	* https://raw.githubusercontent.com/ozairs/apiconnect/master/openid/patch/aaa-ldap-lib.xsl
2. Using the command prompt, create a directory for your project and open the API designer.
	```
	mkdir apic-workspace
	cd apic-workspace
	apic edit
	```
3. Import the API definitions file from **https://raw.githubusercontent.com/ozairs/apiconnect/master/openid/weather-provider-api_1.0.0.yaml**. See instructions [here](https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.apionprem.doc/create_api_swagger.html)
4. In the command prompt, navigate to the workspace directory `apic-workspace` and type the command `apic services:start`. Enter the command `apic services` to view the status. It should take two minutes to start. The following response will be returned once started
	```
	Service apic-workspace-gw running on port 4001.
	```
5. Type the command `docker ps`. You should see the following docker container listed:
	```
	5513b8773bdf        ibm-apiconnect-toolkit/datapower-api-gateway:1.0.5        "/bin/drouter"         2 minutes ago       Up 2 minutes        0.0.0.0:32821->80/tcp, 0.0.0.0:4001->443/tcp, 0.0.0.0:32820->5554/tcp, 0.0.0.0:32819->9090/tcp   apic-workspace_datapower-api-gateway_1
	```
4. Make a note of the port mapped for 9090 (ie 32819->9090). Open the Web browser at https://localhost:32819/dp (your port number is likely different). Login with the userid `admin` and password `admin`.
5. Click the Hamburger icon and select **Files**.
6. Expand `local:/apiconnect/isp` and in the same row, click **Actions ...** and **Upload files...**. Navigate to the location where you saved the files from the first step and click **Add** for the following
	* aaa-oauth-au.xsl
	* aaa-basic-au.xsl
	* aaa-ldap-lib.xsl
7. Make sure you check **Overwrite Existing Files** and click **Upload** and then **Continue**.
8. Repeat the steps above but expand `local:/apiconnect/isp/policy/oauth2-server` and in the same row, click **Actions ...** and **Upload files...** and select **sts-oauth-post-aaa-2.xsl**.
9. Make sure you check **Overwrite Existing Files** and click **Upload** and then **Continue**.
10. Optionally, if can clear the XSL stylesheet cache. Click the Hamburger icon and enter `stylesheet cache`. Flush the cache of each XML manager if its non-empty.

**Note**: You will need to repeat these steps if you restart the API Connect Developer Toolkit.


**Instructions:** 

These instructions assume you are familiar with the basic steps of the API designer. You will import the OAuth provider YAML file which provides support for OIDC connect. We will review it first to understand the core functions.

1. In the **APIs** tab, click the **Add (+)** button and select **Import API from a file or URL**.
2. Click **Import from URL ...** and enter **https://raw.githubusercontent.com/ozairs/apiconnect/master/openid/utility_1.0.0.yaml**. Click **Import** to finish the task.
3. Click **Import from URL ...** and enter **https://raw.githubusercontent.com/ozairs/apiconnect/master/openid/oauth_1.0.0.yaml**. Click **Import** to finish the task.
4. Click the **OAuth 2 OIDC Provider 1.0.0** API. It can be accessed with the URL https://127.0.0.1/oauth2/authorize and https://127.0.0.1/oauth2/token. Take a note of a few items:
	* **Paths**: Token API exposed on paths `/oauth2/authorize` and `/oauth2/token`. The paths `/oauth2/introspect` and `/oauth2/issued` allow you to obtain information about the access token.
	* **OAuth 2**: The default grant types supported, but more important are the scopes available. The scope `openid` triggers the OpenID Connect flow and the scope `weather` is the consumer resource. Add additional scopes for your applications here.
	* **Authentication URL**: the resource owner is authenticated using the endpoint `https://127.0.0.1/utility/basic-auth/spoon/spoon`. This is a mock service in the **utility_1.0.0.yaml** that returns the authenticated credential in JSON format. The format is https://127.0.0.1/utility/basic-auth/{username}/{password}.  Replace `spoon/spoon` with another value if you want to use a different set of username and password. 
	* Click the **Assemble** tab at the top. You will notice several policies that control the generation of the JWT token for OIDC flows. The `set-variable` and `jwt-generate` can be customized if you need to provide custom claims and other JWT information.
5. Open the Weather API and test the unprotected (ie no security) APIs `/current` and `/today` using `curl`. Modify your endpoints below if needed.
	```
	$ curl https://127.0.0.1:4001/current?zipcode=90210 -H "X-IBM-Client-Id: default" -k
	{"zip":"90210","temperature":62,"humidity":90,"city":"Beverly Hills","state":"California","platform":"Powered by IBM API Connect"}

	$ curl https://127.0.0.1:4001/today?zipcode=90210 -H "X-IBM-Client-Id: default" -k
	{"zip":"90210","hi":72,"lo":56,"nightHumidity":91,"city":"Beverly Hills","state":"California","dayHumidity":67}
	```
6. Protect Weather API with OpenID Connect
	Modify the security definition of the Weather API (ie consumer API) to protect access using the OAuth 2 OIDC Provider. It will require consumer applications to obtain an access token before invoking the Weather API.
	* Open the **Weather Provider API** and scroll down to **Security Definitions**. Click the + button and select **OAuth**.
	* Enter the name `openid-password` and select the **Password** flow. Enter the **Token URL** value `https://127.0.0.1/oauth2/token` (using the locally deployed OAuth provider API imported earlier).
	* Scroll down to the scopes section and enter the scopes `weather` and `openid`.
	* In the **Security** section, select **openid-password (OAuth)** and the two scopes.
	* Save the API definition.

7. Test the Weather APIs `/current` and `/today`, you will now get an error because the API is protected using OAuth. In the next step you will obtain an access token to call the same APIs
	```
	curl https://127.0.0.1:4001/today?zipcode=90210 -H "X-IBM-Client-Id: default" -k
	{ "httpCode":"401", "httpMessage":"", "moreInformation":"This server could not verify that you are authorized to access the URL" }
	```
8. Obtain an access token from the OIDC provider (using the resource owner grant type). Invoking OAuth APIs can be tricky because you need to have the appropriate parameters, so we have provided a Postman collection to simplify testing.
	* Open Postman and select **File -> Import -> Import from Link** and enter the value https://www.getpostman.com/collections/951c78382a60b7f7be67.
	* Open the request called `OIDC Password`. Select the **Body** link and notice that a default client id of `default` and client secret of `SECRET` is pre-configured. Adjust the values if your endpoint is different than `https://127.0.0.1:4001`.
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
9. Open the weather request and select the **Headers** tab. Enter the previously copied access token into the Authorization header field and click **Send** to validate that the request is successful.
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

You successfully obtained an OIDC token using the resource owner grant type, which should only be used for trusted OAuth applications since the username and password are shared between the resource owner and OAuth application. Most often you will use the Access Code flow (ie authorization code grant) since it protects the username and password from the OAuth application and still enables sharing of resources to the OAuth application. In the next step, you will setup an Access Code flow. 

When using the API Connect developer toolkit with OAuth Access code flow, you will need to redirect the application to an OAuth client to exchange the authorization code for an access code. This is typically done in an OAuth application, but we can use a couple of techniques to streamline testing.

1. Configure environment for OAuth Access Code 
	* Open a command prompt and make sure your in the project directory (ie same directory as the project yaml files). Enter the command `apic config:set oauth-redirect-uri=https://www.getpostman.com/oauth2/callback`. 
	* Verify that the `oauth-redirect-uri` is set within the file `.apiconnect/config`. You can always manually add the following line:
	`oauth-redirect-uri: 'https://www.getpostman.com/oauth2/callback'`
	* Open Postman Preferences and disable **Automatically follow redirects**.
	![alt](media/postman.png)

2. Protect Weather API with OpenID Connect Access Code flow  
	* Open the **Weather Provider API** and scroll down to **Security Definitions**. Click the + button and select **OAuth**.
	* Enter the name `openid-accesscode` and select the **Access Code** flow. Enter the **Authorize URL** value `https://127.0.0.1/oauth2/authorize` and **Token URL** value `https://127.0.0.1/oauth2/token` (change the hostname to reflect your environment).
	* Scroll down to the scopes section and enter the scopes `weather` and `openid`.
	* In the **Security** section, click the + button to create a new option and select **openid-accesscode (OAuth)** and the two scopes.
	* Save the API definition.	
	**Note:** Multiple security definitions allow you provide multiple options to satisfy consumer security requirements.
	
	![alt](media/security-oidc.png)

3. Open the request called `OIDC Access Code`. Adjust the values if your endpoint is different than `https://127.0.0.1:4001`.
	* Submit the request and make sure you get the following response:
	```
	<?xml version="1.0" encoding="UTF-8"?>
	<html>
		<body>Go ahead</body>
	</html>
	```
	The Access Code flow requires an additional step to obtain an access token. You will need to exchange the code for an access token. This is typically done by an OAuth application but you will simulate one for simplicity.
	* Click the **Headers** tab and copy the value after `code=`
	* Copy the `code` so it remains on your clipboard. 
	* Open the `OAuth AC to Token` request and click the **Body** tab. Paste the code value into the `code` field. Click **Send** and verify you receive an access token
4. Open the Weather request and select the **Headers** tab. Enter the previously copied access token into the Authorization header  after the `Bearer` string and click **Send**. Validate that the request is successful.
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