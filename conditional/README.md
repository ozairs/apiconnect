# 2. Build conditional flows for dynamic API execution 

**Authors** 
* [Ozair Sheikh](https://github.com/ozairs)

**Prerequisites**

* API Connect Developer Toolkit 5.0.7.1
* Import the API definitions file from **https://github.com/ozairs/apiconnect/blob/master/conditional/weather-provider-api_1.0.0.yaml**. See instructions [here](https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.apionprem.doc/create_api_swagger.html)

In this tutorial, you will learn how to implement dynamically flow logic without writing any code. 

**Instructions:** 

We will examine the existing conditional policy in the Assembly.

1. Click the **Assembly** tab select the existing **Operation Switch** policy.
	![alt](images/conditional.png)
2. We will recreate this operation-switch policy so you understand the steps.
3. Delete the **operation-switch** policy. Click inside the policy and click the delete icon on the top right-hand corner.
4. Drag the **operation-switch** policy into the dotted box within the Assembly area. An orange box will appear to visually aid in the highlighted area.
5. Select the dropdown beside **Case** and select `get /current`. 

6. Click the **+ Case** button and select `get /today`. Click the X button to close the action. Each operations requires a different endpoint to be invoked. In the next step, you will add an Invoke policy.

7. Drag an Invoke action into the case for `get /current` and enter the name `invoke-current`. When you drag the action into this case, an orange box will appear to indicate the action can be added. Move around the Invoke action until you get the orange box. Enter the URL https://myweatherprovider.mybluemix.net/current?zipcode=$(request.parameters.zipcode). The `{request.parameters.zipcode}` variable is the query parameter (string after ?) in the incoming URL you tested earlier. Uncheck `Stop on error` since you won't define any error handling logic.
8. Drag another Invoke action into the case for `get /today` and enter the name `invoke-today`. Enter the URL https://myweatherprovider.mybluemix.net/today?zipcode=$(request.parameters.zipcode). The same `{request.parameters.zipcode}`  variable is expected for this operation. Similarly, uncheck `Stop on error`.
	![Assembly](images/conditional.png)
9. Save your changes and test both operations using the test tool. 
10. Click the **Play icon** to open the built-in test tool. Select the **get /current** operation and enter the zipcode `90210`. Click the **Invoke** button to test our API. 
11. Change the operation to **get /today** and click the **Invoke** button. You should see a different JSON reponse than the previous operation. Close the test editor once your happy with the results.

In this tutorial, you learned how to build a simple conditional statement based on the incoming API operation.

**Next Tutorial**: [Write JavaScript to enrich API payloads](../master/gatewayscript/README.md)