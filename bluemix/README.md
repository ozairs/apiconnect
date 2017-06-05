# 8. Packaging APIs for deployment on Bluemix

In this tutorial, you will package and deploy API definitions to IBM Blumix so they are accessible outside of your local environment. In a real-world scenario, you would publish them into a dev portal where developers subscribe to the API and obtain an API key. For testing purposes, you will simply use a development API key.

**Authors** 
* [Ozair Sheikh](https://github.com/ozairs)

**Prerequisites:** 

* API Connect Developer Toolkit 5.0.7.1
* Import the API definitions file from 
	* [https://github.com/ozairs/apiconnect/blob/master/bluemix/weather-provider-api_1.0.0.yaml]() 
	* [https://github.com/ozairs/apiconnect/blob/master/bluemix/weather_1.0.0.yaml](). 
	* [https://github.com/ozairs/apiconnect/blob/master/bluemix/oauth_1.0.0.yaml](). 
	* [https://github.com/ozairs/apiconnect/blob/master/bluemix/utility_1.0.0.yaml](). 

	See instructions [here](https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.apionprem.doc/create_api_swagger.html)
* For testing, you will to download [Postman](https://www.getpostman.com/). 
* Download the Postman collection [here](https://www.getpostman.com/collections/951c78382a60b7f7be67)

**Instructions:** 

**Note**: New terminology will be discussed in subsequent sections, so let's formerly define them now:
* **Product**: packaging of one or more APIs into a single group that is a deployable unit and enables enforcement of rate limit definitions.
* **Catalog**: deployment target for a `product` and provides access to many API management capabilities.

1. Login to Bluemix and select the Catalog link. In the search box, type API Connect and click on the API Connect link.
2. Select the Essentials plan and click Create and follow the prompts to provision the service. The provisioning steps may take a few moments to complete.
3. Once complete, you should be redirected to the **Dashboard** and see a large icon with the name `Sandbox`. 
4. Click the **Sandbox** catalog to open the Dashboard and then click on **Settings**.
5. In **Overview**, the **Automatic subscription** toggle should already be selected. Click the Show button to note the client ID and client secret. For example, client id is `d03c438a-2010-4f21-8520-c111a86a9f16` and client secret is `rH1lA6wO5nL6gC5uD5tV0pE1hV4gO5lV2yN2uG5hB1hR3iT6jF`.
6. Select **Endpoints** and make a note of the URL, such as `https://api.us.apiconnect.ibmcloud.com/ozairscaibmcom-dev/sb/`.

Let's switch back to the API Connect Developer toolkit.

7. Click the **APIs** tab and select the **Weather Provider API**.
8. Select the **Design** tab.
9. Modify the API definitions that are using `127.0.0.1:443`.
	* Click the **Source** tab in the Weather API and find and replace `127.0.0.1` with `api.us.apiconnect.ibmcloud.com/ozairscaibmcom-dev/sb/`
	* Repeat the same steps for the **`127.0.0.1` with `api.us.apiconnect.ibmcloud.com/ozairscaibmcom-dev/sb/`. Remove any extra slashes if needed.
10. Click the **Save** icon. Your all set to publish the product to IBM Bluemix!
11. Click the **Publish** button in the nav bar.
12. Click **Add IBM Bluemix** target, and sign-in with your credentials.
13. The **Sandbox** catalog provisioned will be shown. Make sure its selected and click **Save**.
14. Click the **Publish** button (leave the defaults unchecked) and make sure you get a successful publish message. 
  Now we have to go back to the **Sandbox** catalog in IBM Bluemix to obtain the URL for testing.
15. Open Postman and right-click the **OAuth Password** request and clone the request (right-click and select **Duplicate**). Change the URL to reflect your endpoint but keeping `/oauth/token`. For example change `https://127.0.0.1/oauth/token` to `https://api.us.apiconnect.ibmcloud.com/ozairscaibmcom-dev/sb/oauth/token`.
16. In the Body tab, change the client id and client secret to reflect your values obtained in the previous steps. Click **Send** and make sure you get back an access token.
17. Repeat the steps above to change the Weather request to invoke it with the access token from the previous step. Make sure you get back a valid response!

In this tutorial, you learned how to publish your API definition to Bluemix for availability outside your local environment.