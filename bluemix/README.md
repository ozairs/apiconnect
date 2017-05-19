# 7. Packaging APIs and Enforcing Rate Limits

Now the fun part of the lab - you know the saying, great things happen to those with patience! In this tutorial, you will package and deploy the API definitions to IBM Blumix so they are accessible for testing. In a real-world scenario, you would publish them into a dev portal where developers subscribe to the API and obtain an API key. For for testing purposes, you will simply use a development API key.

1. Login to Bluemix and select the Catalog link. In the search box, type API Connect and click on the API Connect link.
2. Select the Essentials plan and click Create and follow the prompts to provision the service. The provisioning steps may take a few moments to complete.
3. Once complete, you should be redirected to the **Dashboard** and see a large icon with the name `Sandbox`. 
4. Click the **Sandbox** catalog to open the Dashboard and then click on **Settings**.
5. In **Overview**, the **Automatic subscription** toggle should already be selected. Click the Show button to note the client ID and client secret. For example, client id is `d03c438a-2010-4f21-8520-c111a86a9f16` and client secret is `rH1lA6wO5nL6gC5uD5tV0pE1hV4gO5lV2yN2uG5hB1hR3iT6jF`.
6. Select **Endpoints** and make a note of the URL, such as `https://api.us.apiconnect.ibmcloud.com/ozairscaibmcom-dev/sb/`.

This is all the steps needed to setup the API Connect environment, let's switch back to the API Connect Developer toolkit.

**Note**: New terminology will be discussed in subsequent sections, so let's formerly define them now:
* **Product**: packaging of one or more APIs into a single group that is a deployable unit and enables enforcement of rate limit definitions.
* **Catalog**: deployment target of a `product` and provides access to many API management capabilities.

1. Modify the APi definitions that are using `127.0.0.1:443`.
	* Click the **Source** tab in the Pokemon API and find and replace `127.0.0.1` with `api.us.apiconnect.ibmcloud.com/ozairscaibmcom-dev/sb/`
	* Repeat the same steps for the **`127.0.0.1` with `api.us.apiconnect.ibmcloud.com/ozairscaibmcom-dev/sb/`. Remove any extra slashes if needed.
2. Select the **Products** tab and click **Add + -> New Product**.
3. Enter the name `pokemon` and click **Create product**.
4. Click the recently created product and click APIs (in the left nav bar).
5. Click the + button to add the following APIs
  * OAuth2 OIDC Provider
  * pokemon
  * utility
6. Click **Apply** when complete.
7. Below APIs, expand the **Plans** section.
8. You can define the rate limits for your product. Default rate plan of 100 calls / hour is pre-defined. Multiple rate plans can be defined to offer different quality of service. Burst limits allow you to exceed the rate limit to account for periods of. **Hard limit** fails transactions above the rate limit threshold. Rate limits can be applied to individual API operations if needed.
For more details on the various options, see [here](https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.toolkit.doc/task_apim_cli_product_yaml_plans.html)
9. Click the **Save** icon.
  Your all set to publish the product to IBM Bluemix!

10. Click the **Publish** button in the nav bar.
11. Click **Add IBM Bluemix** target, and sign-in with your credentials.
12. Depending on your region, the **Sandbox** catalog provisioned early will be available. Make sure its selected and click **Save**.
13. Click the **Publish** button (leave the defaults unchecked) and make sure you get a successful publish message. 
  Now we have to go back to **Sandbox** catalog in IBM Bluemix to obtain the URL for testing.

14. Open Postman and right-click the **OAuth Password** request and clone the request (right-click and select **Duplicate**). Change the URL to reflect your endpoint but keeping `/oauth/token`. For example change `https://127.0.0.1/oauth/token` to `https://api.us.apiconnect.ibmcloud.com/ozairscaibmcom-dev/sb/oauth/token`.
15. In the Body tab, change the client id and client secret to reflect your values obtained in the previous steps. Click **Send** and make sure you get back an access token.
16. Repeat the steps above to change the Pokemon request to invoke it with the access token from the previous step. Make sure you get back a valid response!

In this tutorial, you learned how to publish your API definition to Bluemix for availability outside your local environment.