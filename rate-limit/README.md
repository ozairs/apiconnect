# 7. Enforcing Rate Limits for APIs

In this tutorial, you will package APIs into a product for deployment. Each product can have one or more plans. The default plan provides a basic rate limit policy. You will modify this policy to enforce a hard rate limit to ensure that consumers cannot send more traffic than the plan limit.

**Authors** 
* [Ozair Sheikh](https://github.com/ozairs)

**Prerequisites:** 

* API Connect Developer Toolkit 5.0.7.1
* Import the API definitions file from 
	* [https://github.com/ozairs/apiconnect/blob/master/rate-limit/weather_1.0.0.yaml](). 
	* [https://github.com/ozairs/apiconnect/blob/master/rate-limit/oauth_1.0.0.yaml](). 
	* [https://github.com/ozairs/apiconnect/blob/master/rate-limit/utility_1.0.0.yaml](). 

	See instructions [here](https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.apionprem.doc/create_api_swagger.html)
* For testing, you will to download [Postman](https://www.getpostman.com/).

**Instructions:** 

**Definition**: New terminology will be discussed in subsequent sections, so let's formerly define them now:
* **Product**: packaging of one or more APIs into a single group that is a deployable unit and enables enforcement of rate limit definitions.

1. Select the **Products** tab and click **Add + -> New Product**.
2. Enter the name `weather` and click **Create product**.
3. Click the recently created product and click APIs (in the left nav bar).
4. Click the + button to add the following APIs
  * OAuth2 OIDC Provider
  * Weather Provider API
  * utility
5. Click **Apply** when complete.
6. Below APIs, expand the **Plans** section.
7. You can define the rate limits for your product here. Default rate plan of 100 calls / hour is pre-defined. Multiple rate plans can be defined to offer different quality of service. Burst limits allow you to exceed the rate limit to account for periods of unusually high traffic. **Hard limit** fails transactions above the rate limit threshold. Rate limits can be applied to individual API operations if needed.
For more details on the various options, see [here](https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.toolkit.doc/task_apim_cli_product_yaml_plans.html)
8. Change the default rate plan from **100 calls / hour** to **10 calls / minute**.
9. Check the **Enforce Hard Limit** checkbox and click the save button.

Your now ready to test the rate limit policy.

10. Obtain an access token from the OIDC provider (using the resource owner grant type).
	1. Open Postman and select **File -> Import -> Import from Link** and enter the value https://www.getpostman.com/collections/951c78382a60b7f7be67.
	2. Open the request called `OIDC Password`. Select the **Body** link and notice that a default client id of `default` and client secret of `SECRET` is pre-configured. Adjust the values if your endpoint is different than `https://127.0.0.1:4001`.
	3. Submit the request and validate that you get back an access token and JWT token.
	```
	{
		"token_type": "bearer",
		"access_token": "<sanitized>",
		"expires_in": 3600,
		"scope": "pokemon openid",
		"refresh_token": "<sanitized>",
		"id_token": "<sanitized>"
	}
	```
	4. Copy the access token so it remains on your clipboard. You are now ready to call the Weather API!
11. Open the Weather request and select the **Headers** tab. Enter the previously copied access token into the Authorization header field and click **Send** to validate that the request is successful.
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
12. Click the **Headers** tab and scroll down **X-RateLimit-** headers
	```
	X-RateLimit-Limit →name=rate-limit,10
	X-RateLimit-Remaining →name=rate-limit,9
	X-RateLimit-Reset →name=rate-limit,22
	```
13. Send 10 more requests and then switch over to the body link. The following response will appear that indicates that the rate limit is exceeded.
	```
	{
	"httpCode": "429",
	"httpMessage": "Too Many Requests",
	"moreInformation": "Rate Limit exceeded"
	}
	```
	
In this tutorial, you learned how to enforce rate limits for your product (collection of APIs).

**Next Tutorial**: [Packaging APIs for deployment on Bluemix](../master/bluemix/README.md)