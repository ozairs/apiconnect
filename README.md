**Tutorial Series: Accelerate delivery of API & Microservices with API Assembly**

**Prerequisites**

* [API Connect Toolkit 5071 with DataPower](https://www.ibm.com/support/knowledgecenter/SSMNED_5.0.0/com.ibm.apic.toolkit.doc/tapim_apic_test_with_dpdockergateway.html)
* [curl](https://curl.haxx.se)
* [Git](https://git-scm.com) (optional)

**Series Overview**

I have too often falled into a trap thinking that a visual-style development tool will accelerate development of my project. At first, the idea looks promising with a fancy prototype and generated code, but as you need to tweak your code, you often run into issues and solving it turns into a 'stack-overflow / googling' exercise. 

The right balance needs to be available - you need productive visual tools that solve the common problem and at the same time provide the flexibility to drop-down and write code when needed. Enter the **API Connect assembly editor**, which provides a visual policy flow experience with built-in programming constructs to help accelerate delivery of API and microservice implementations. This tool is not here to write your service implementation, but act as a 'gateway' to enforce API and microservice security policies, apply rate limits and perform payload / header manipulation before proxying to the service backend.

In this tutorial series, you will learn how to build a first-class API definition to secure and rate-limit service backends.

<!-- TOC -->

- [1. Getting Started with API Connect Developer Toolkit](../getting-started/README.md)
- [2. Build conditional flows for dynamic API execution](../conditional/README.md)
- [3. Write JavaScript to enrich API payloads](../gatewayscript/README.md)
- [4. Handling API Errors](../error-handling/README.md)
- [5. Protect access to API services with Auth0 & JWT](../jwt/README.md)
- [6. Protect access to APIs using OpenID Connect](../openid/README.md)
- [7. Packaging APIs and Enforcing Rate Limits](../bluemix/README.md)