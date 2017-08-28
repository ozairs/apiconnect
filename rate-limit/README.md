# Enforcing Rate Limits for APIs

In this tutorial, you will package APIs into a product for deployment. Each product can have one or more plans. The default plan provides a basic rate limit policy. You will modify this policy to enforce a hard rate limit to ensure that consumers cannot send more traffic than the plan limit.

**Authors** 
* [Ozair Sheikh](https://github.com/ozairs)

**Prerequisites:** 

* [API Connect Developer Toolkit 5.0.7.1](https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.toolkit.doc/tapim_cli_install.html)
* Completion of any tutorial within the [series](../master/README.md)

**Instructions:** 

**Definition**: New terminology will be discussed in subsequent sections, so let's formerly define them now:
* **Product**: packaging of one or more APIs into a single group that is a deployable unit and enables enforcement of rate limit definitions.

1. Select the **Products** tab and click **Add + -> New Product**.
2. Enter the name `weather` and click **Create product**.
3. Click the recently created product and click APIs (in the left nav bar).
4. Click the + button to add the following APIs
  * Weather Provider API
  * OAuth2 OIDC Provider (if available)
  * utility (if available)
5. Click **Apply** when complete.
6. Below APIs, expand the **Plans** section.
7. You can define the rate limits for your product here. Default rate plan of 100 calls / hour is pre-defined. Multiple rate plans can be defined to offer different quality of service. Burst limits allow you to exceed the rate limit to account for periods of unusually high traffic. **Hard limit** fails transactions above the rate limit threshold. Rate limits can be applied to individual API operations if needed.
For more details on the various options, see [here](https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.toolkit.doc/task_apim_cli_product_yaml_plans.html)
8. Change the default rate plan from **100 calls / hour** to **10 calls / minute**.
9. Check the **Enforce Hard Limit** checkbox and click the save button.

Your now ready to test the rate limit policy.

10. If your using an OAuth secured API, obtain an access token from the OAuth provider (using the resource owner grant type).
11. Obtain an access token from the OAuth provider (using the resource owner grant type) with Postman.
	* Open Postman and select **File -> Import -> Import from Link** and enter the value https://www.getpostman.com/collections/9ab248322bd2f0a75eea.
	* Open the request called `OAuth Password`. Select the **Body** link and notice that a default client id of `default` and client secret of `SECRET` is pre-configured. Adjust the values if your endpoint is different than `https://127.0.0.1:4001`.
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
	* Copy the access token so it remains on your clipboard. You are now ready to call the Weather API!
12. Open the **Weather (Resource Call)** request and select the **Headers** tab and notice the variable `{{access_token}}`. The access token is already populated for you via a helper Postman script. If your still want to copy the access token, you can manually replace add it to the Authorization header field. Click **Send** to validate that the request is successful.
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
13. Click the **Headers** tab and scroll down **X-RateLimit-** headers
	```
	X-RateLimit-Limit →name=rate-limit,10
	X-RateLimit-Remaining →name=rate-limit,9
	X-RateLimit-Reset →name=rate-limit,22
	```
14. Send 10 more requests and then switch over to the body link. The following response will appear that indicates that the rate limit is exceeded.
	```
	{
	"httpCode": "429",
	"httpMessage": "Too Many Requests",
	"moreInformation": "Rate Limit exceeded"
	}
	```
	
In this tutorial, you learned how to enforce rate limits for your product (collection of APIs).