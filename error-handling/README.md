# 4. Handling API Errors

**Authors** 
* [Ozair Sheikh](https://github.com/ozairs)

**Prerequisites**

* API Connect Developer Toolkit 5.0.7.1
* Import the API definitions file from **https://github.com/ozairs/apiconnect/blob/master/error-handling/weather-provider-api_1.0.0.yaml**. See instructions [here](https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.apionprem.doc/create_api_swagger.html)

In this tutorial, you will learn how to catch errors within the API assembly. Errors can range from built-in (ie connection failure) or custom (ie InsuffienctFundsException). The API assembly provides a single global error handle to catch errors thrown by any policy.

**Instructions:** 

1. Open the API designer and select the **Assembly** tab.
2. The **Show Catches** toggle provides an visible area to defineerror handling logic for common error conditions. The default errors are defined [here](http://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.toolkit.doc/ref_toolkit_catch_errors.html). 

	Multiple approaches are available to throw errors:
	1. The API assembly provides a `throw` policy that triggers the global error handler into the **catch** space, which can contain policies to return an error message to the client.
	2. Throw errors in your JavaScript code when an error condition is reached. For example, when the Invoke policy returns an non-200 error. You will use this approach next to throw and catch errors.
3. Switch back to the existing JavaScript policy. Replace the existing code with the following:
	```
	//get the payload
	var json = apim.getvariable('message');
	console.info("json %s", JSON.stringify(json));

	//code to inject new attribute 
	if (json.body && json.status.code == '404') {
		console.error("throwing apim error %s", JSON.stringify(json.status.code));
		apim.error('ConnectionError', 500, 'Service Error', 'Failed to retrieve data');
		
	}
	else {
		json.body.platform = 'Powered by IBM API Connect';
		json.headers.platform = 'Powered by IBM API Connect';
	}

	//set the payload
	apim.setvariable('message.body', json.body);
	apim.setvariable('message.headers', json.headers);
	```
4. Click the catch area and the **catch+** button and add the following errors:
	* Connection Error
	* RuntimeError
	![alt](images/catch.png)
5. Close the panel once done.
6. Each error condition can execute a set of policies. Add a set-variable action and click the **+Create** button. Name it `Rewrite Error` and enter the following:
	* Action: set
	* Set: message.body
	* Type: string
	* Value: {"message": "Error occurred during search operation."}
	![alt](images/error-setvar.png)
6. Save the assembly.
7. Testing this policy requires an actual error to occur. Click the **Play icon** to open the built-in test tool. Test the **get /current** operation, enter an **zipcode** value of `0`. You should see the error message `{"message": "Error occurred during search operation."}`.

In this tutorial, you learned how to catch errors during execution of the API assembly and return an error message back to the API consumer.

**Next Tutorial**: [Protect access to API services with Auth0 & JWT](../master/jwt/README.md)