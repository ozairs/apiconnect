# 1. Getting Started with API Connect Developer Toolkit

**Authors** 
* [Tony Ffrench](https://github.com/tonyffrench)
* [Ozair Sheikh](https://github.com/ozairs)

**Prerequisites**
* Download the project from [here](https://github.com/ozairs/apiconnect), either using git command-line command (ie `git clone https://github.com/ozairs/apiconnect`) or the ZIP file from the Web browser and install it on your local system. Make a note of this location.

In this tutorial, you will learn how to use the API Connect Developer toolkit with DataPower Gateway to expose an existing REST service as an API and test it directly within the tool.

1. Using the command prompt, create a directory for your project in the same location as the cloned project (`<path>/apiconnect`) and open the API designer.
	```
	cd apiconnect
	mkdir apic-workspace
	cd apic-workspace
	apic edit
	```
	**Note**: if you don't have an IBM Id, you can also login using `SKIP_LOGIN=true apic edit`. You will need an IBM id to publish API definitions on Bluemix for your friends / family / googlers to discover.
2. Test the backend service (ie the service that will be proxied)
	
	The backend service is located here: [https://pokemons.mybluemix.net/api/pokemons/](https://pokemons.mybluemix.net/api/pokemons/). Go ahead and try it out on a Web browser to make sure its available. Add an integer after the URL (ie [https://pokemons.mybluemix.net/api/pokemons/1](https://pokemons.mybluemix.net/api/pokemons/1)) to retrieve individual items.
	```
	{
	"data": {
		"moves": "slow"
	},
	"height": "70",
	"name": "ivysaur",
	"weight": 200,
	"id": "1"
	}
	```
3. Import API definitions file
	1. Click the **Add (+)** button and select **Import API from a file or URL**.
    2. Click **Select File** and navigate to **getting-started/pokemon_1.0.0.yaml**. Click **Import** to finish the task.
    3. Click the **pokemon 1.0.0** API. In the **Design** tab, make a note of a few items:
    	* API exposed on the path `/pokemon` & `/pokemon/{id}`
		![alt](images/paths.png)
		* Click the **Assemble** tab at the top. You will notice a single `Invoke` action. It currently references the URL `https://pokemons.mybluemix.net/api/pokemons/`.
		
The API designer includes a built-in test tool, so you don't need any external tool to perform a quick validation. We need to setup a few things before we start testing.

5. Start the Gateway by clicking the Play button at the bottom. Wait till the gateway is fully started - it may take a minute or so. 

  The first time you start Gateway, it will install the pre-requisite components - two docker containers. Examine the details from the command prompt with the command:
  ```
  $ cd <path>/apiconnect/apic-workspace
  $ apic services
  Service apic-workspace-gw running on port 4001.
  ```
  This apic service depends upon the following docker containers. Enter the command `docker ps`. The `datapower-api-gateway` container is the DataPower Gateway that executes the policies. The Web GUI can be viewed using the mapped 9090 port with credentials `admin/admin`. The `datapower-mgmt-server-lite` simulates the API manager capabilities.
  ```
  CONTAINER ID        IMAGE                                                      COMMAND                CREATED             STATUS              PORTS                                                                                            NAMES
84287c1249c3        ibm-apiconnect-toolkit/datapower-api-gateway:1.0.10        "/bin/drouter"         6 days ago          Up 6 days           0.0.0.0:32797->80/tcp, 0.0.0.0:4001->443/tcp, 0.0.0.0:32796->5554/tcp, 0.0.0.0:32795->9090/tcp   apiassembly_datapower-api-gateway_1
634b3dcfeed0        ibm-apiconnect-toolkit/datapower-mgmt-server-lite:1.0.10   "node lib/server.js"   6 days ago          Up 6 days           0.0.0.0:32794->2443/tcp                                                                          apiassembly_datapower-mgmt-server-lite_1
  ```
  **Note:** If you run into errors, you can manually start / stop the gateway with the commands `apic services:start` and `apic services:stop`.

6. Click the **Play icon** ![alt](images/play.png) to open the built-in test tool. Select the **get /pokemon** operation. Click the **Invoke** button to test our API. The first time you test, you will get security warning so open the link to accept the self-signed certifcate. Click the **Invoke** button again to see the same Pokemon REST response but this time its executed via the API Gateway.

7. Click the **Invoke** button a few more times to test the API. Notice that the API returns headers with `x-ratelimit-remaining and x-ratelimit-limit`. The API gateway adds these response headers to provide a hint to the consumer on the number of APIs they are allowed to execute within a particular time period. Although, we did not define a rate limit for the API, a default rate limit policy is enforced. You will learn more about rate limit when we talk about packaging our API for deployment in a standalone development environment.

APIs are protected using an API key, which only allows access to consumers with a valid key.
The test tool did a little bit of magic by injecting a client ID into the header. If you wanted to run the same request using a test tool such as `curl` then run the following command:
	`curl https://127.0.0.1:4001/api/pokemon -H "X-IBM-Client-Id: default" -k`

In this tutorial, you learned how to the API Connect developer toolkit with the DataPower Gateway on Docker to expose an existing REST service as an API.