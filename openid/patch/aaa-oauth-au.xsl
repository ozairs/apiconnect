<?xml version="1.0"?>
<!--
 ***************************************************** {COPYRIGHT-TOP} ***
* Licensed Materials - Property of IBM
* 5725-L30
*
* (C) Copyright IBM Corporation 2014
*
* US Government Users Restricted Rights - Use, duplication, or
* disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 ********************************************************** {COPYRIGHT-END}***
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions"
    extension-element-prefixes="dp"
    exclude-result-prefixes="dp">

    <xsl:include href="aaa-ldap-lib.xsl"/>

    <!-- Tenant and API information is retrieved from context by included 'aaa-ldap-lib.xsl -->

    <xsl:template match="/">

      <!--
        Authorization Code Grant (Confidential client)
          1) first authorization_request

            <oauth-id type="authorization_request">
              <response_type count="1" src="url">code</response_type>
              <state count="1" src="url">xyz</state>
              <client_id count="1" src="url">c-code</client_id>
              <original-url count="1" type="request">https://172.16.183.129:443/test200/oauth/authorize?response_type=code...</original-url>
              <redirect_uri count="1" src="url">https://mycoolapp.example.com/</redirect_uri>
              <scope count="1" src="url">/test200</scope>
            </oauth-id>

          2) second authorization_request, end-user sends approval (or not) for the auth form

            <oauth-id type="authorization_request">
              <response_type count="0">code</response_type>
              <state count="0">xyz</state>
              <client_id count="1" src="body">c-code</client_id>
              <dp-state count="1">t5ZkqqDfgtrtd+30OmeytA==</dp-state>
              <original-url type="dp-state" count="1">https://172.16.183.129:443/test200/oauth/authorize?response_type=code...</original-url>
              <resource-owner count="1">alice</resource-owner>
              <nonce>l+ATTYEi8jo=</nonce>
              <algorithm>0</algorithm>
              <not-before>61926764</not-before>
              <not-after>61927064</not-after>
              <approve>true</approve>
              <authorization-request>
                <args src="body">
                  <arg name="dp-state">t5ZkqqDfgtrtd+30OmeytA==</arg>
                  <arg name="resource-owner">alice</arg>
                  <arg name="dp-data">0:61926764:61927064:code:l+ATTYEi8jo=:xyz</arg>
                  <arg name="redirect_uri">https://mycoolapp.example.com/</arg>
                  <arg name="scope">/test200</arg>
                  <arg name="original-url">https://172.16.183.129:443/test200/oauth/authorize?response_type=code&amp;client_id=mycoolapp-withoauth&amp;state=xyz&amp;scope=/test200&amp;redirect_uri=https://mycoolapp.example.com/</arg>
                  <arg name="client_id">c-code</arg>
                  <arg name="approve">true</arg>
                </args>
              </authorization-request>
              <redirect_uri count="1">https://mycoolapp.example.com/</redirect_uri>
              <scope count="1">/test200</scope>
            </oauth-id>

          3) access_request

            <oauth-id type="access_request">
              <code count="1">AAJczLXEnj/xcqbn7FbJwCplWHZ2C0NCU2LNRdvetOo7GEgAC...</code>
              <grant_type count="1">authorization_code</grant_type>
              <client_id src="basic-auth" count="1">c-code</client_id>
              <client_secret src="basic-auth" sanitize="true" count="1">mypassw0rd</client_secret>
              <original-url count="1" type="request">https://172.16.183.129:443/test200/oauth/authorize</original-url>
              <redirect_uri count="1">https://mycoolapp.example.com/</redirect_uri>
            </oauth-id>
      -->

      <xsl:variable name="request"  select="/identity/entry[@type='oauth']/oauth-id" />
      <xsl:variable name="res-type" select="$request/response_type/text()" />

      <!-- we may have already authenticated this user, if this is the case, we don't need to re-run
           LDAP or Authorization-URL authentication, let DataPower handle the OAuth Authorization Form submission
           and/or the exchange of OAuth Code to Token -->

      <xsl:variable name="run-au">
        <xsl:choose>
          <xsl:when test="$request/grant_type = 'password'">yes</xsl:when>
          <xsl:when test="$request/@type = 'access_request'"/>
          <xsl:when test="dp:variable('var://context/_apimgmt/requested-grant-type') = 'introspect'"/>
          <xsl:when test="$request/@type = 'authorization_request' and count($request/authorization-request/*) &gt; 0"/>
          <xsl:otherwise>yes</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <!-- DEBUG -->
      <xsl:if test="$debug1">
        <xsl:for-each select="/identity/entry[@type='oauth']/oauth-id">
          <xsl:message dp:type="apiconnect" dp:priority="debug">
            <xsl:text>aaa-oauth-au: oauth-id [type=</xsl:text>
            <xsl:value-of select="./@type" />
            <xsl:text>]</xsl:text>
            <xsl:if test="$run-au != 'yes'">
              <xsl:text> already authenticated</xsl:text>
            </xsl:if>
          </xsl:message>
        
          <xsl:message dp:type="apiconnect" dp:priority="debug">
            <xsl:text>aaa-oauth-au: oauth-id: </xsl:text>
            <xsl:copy-of select="." />
          </xsl:message>
        </xsl:for-each>
      </xsl:if>

      <xsl:if test="string(/identity/entry[@type='oauth']/oauth-verified[@state='ok']/result//resource_owner) != ''">
        <dp:set-variable name="'var://context/_apimgmt/authenticated-username'" 
                         value="string(/identity/entry[@type='oauth']/oauth-verified[@state='ok']/result//resource_owner)"/>
      </xsl:if>

      <!-- Execute only if we have to run customized AU -->
      <xsl:choose>
        <xsl:when test="$run-au = 'yes'">

          <xsl:variable name="oAuthPolicy" select="dp:variable('var://context/_apimgmt/oauth/policy')" />
          <xsl:variable name="oAuthProperties">
            <xsl:choose>
              <xsl:when test="string-length($oAuthPolicy/type) > 0">
                <xsl:copy-of select="$oAuthPolicy" />
                <authenticationURL><xsl:value-of select="$oAuthPolicy/authenticationUrl" /></authenticationURL>
                <authenticationURLsslProfile><xsl:value-of select="$oAuthPolicy/authenticationUrlsslProfile" /></authenticationURLsslProfile>
              </xsl:when>
              <xsl:otherwise>
                <xsl:for-each select="$oAuthPolicy/properties/property"> <!-- legacy: 4020 -->
                  <xsl:element name="{./@name}">
                    <xsl:value-of select="./text()"/>
                  </xsl:element>
                </xsl:for-each>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>  <!-- oAuthProperties -->

          <xsl:if test="$debug1">
            <xsl:message dp:type="apiconnect" dp:priority="debug">
              <xsl:text>aaa-oauth-au: oAuthProperties= </xsl:text>
              <xsl:copy-of select="$oAuthProperties" />
            </xsl:message>
          </xsl:if>

          <xsl:if test="count($tenant-policy) = 0 or count($api-policy) = 0">
             <xsl:message dp:type="apiconnect" dp:priority="error">
                 <xsl:text>Internal: Missing tenant-policy or api-policy</xsl:text>
             </xsl:message>
             <dp:reject/>
          </xsl:if>

          <xsl:variable name="username">
            <xsl:choose>
                <xsl:when test="dp:variable('var://context/_apimgmt/requested-grant-type') = 'password'">
                    <xsl:value-of select="dp:variable('var://context/_apimgmt/username')" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="dp:auth-info('basic-auth-name')" />
                </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>  <!-- username -->

          <xsl:variable name="password">
            <xsl:choose>
                <xsl:when test="dp:variable('var://context/_apimgmt/requested-grant-type') = 'password'">
                    <xsl:value-of select="dp:variable('var://context/_apimgmt/password')" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="dp:auth-info('basic-auth-password')" />
                </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>  <!-- password -->

          <xsl:choose>
            <xsl:when test="string-length($username) = 0">
              <xsl:message dp:type="apiconnect" dp:priority="error">
                <xsl:text>custom-au: missing resource credentials, send challenge</xsl:text>
              </xsl:message>
              <xsl:call-template name="error">
                <xsl:with-param name="code" select="'401'"/>
                <xsl:with-param name="reason" select="'Unauthorized'"/>
                <xsl:with-param name="challenge" select="'Basic'" />
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <dp:set-variable name="'var://context/_apimgmt/authenticated-username'" value="string($username)"/>
            </xsl:otherwise>
          </xsl:choose>

          <xsl:if test="dp:variable('var://context/_apimgmt/requested-grant-type') != 'client'">
            <xsl:choose>
              <xsl:when test="$oAuthProperties/type = 'authUrl'">
                <!-- Using Authentication URL -->
                <xsl:call-template name="basic-auth-authurl">
                    <xsl:with-param name="user"  select="$username"/>
                    <xsl:with-param name="pass"  select="$password"/>
                    <xsl:with-param name="sslProfile"  select="$oAuthProperties/authenticationURLsslProfile" />
                    <xsl:with-param name="url"   select="$oAuthProperties/authenticationURL" />
                </xsl:call-template>
              </xsl:when>
              <xsl:when test="$oAuthProperties/type = 'ldap'">
                <!-- LDAP Authentication -->
                <xsl:call-template name="ldap-authenticate">
                    <xsl:with-param name="user"     select="$username"/>
                    <xsl:with-param name="pass"     select="$password"/>
                    <xsl:with-param name="registry" select="$oAuthProperties/authentication.x-ibm-authentication-registry" />
                  </xsl:call-template>
              </xsl:when>
            </xsl:choose>
          </xsl:if>  <!-- handle non client grant type, resource owner authentication -->

          <!-- Check for any errors and return result if no errors. -->
          <xsl:variable name="error-code" select="dp:variable('var://context/api/error-protocol-response')"/>
          <xsl:choose>
            <xsl:when test = "$error-code">
              <xsl:message dp:type="apiconnect" dp:priority="error">
                <xsl:value-of select="concat('custom-au: api-authenticate-error-code: ', $error-code)"/>
              </xsl:message>
            </xsl:when>
            <xsl:otherwise>
            </xsl:otherwise>
          </xsl:choose>

        </xsl:when>  <!-- run-au = yes -->

        <xsl:when test="dp:variable('var://context/_apimgmt/requested-grant-type') = 'introspect' and
                        /identity/entry[@type='oauth']/oauth-verified/@state = 'ok'">
          <oauth state='ok'>
            <xsl:copy-of select="/identity/entry[@type='oauth']/oauth-verified/result/*"/>
            <client_name><xsl:value-of select="/identity/entry[@type='oauth']/OAuthSupportedClient/summary"/></client_name>
          </oauth>
        </xsl:when>
        <xsl:otherwise/>
      </xsl:choose>

      <!-- must return non-empty nodeset to indicate AU success -->
      <apim>
        <client_id><xsl:value-of select="dp:variable('var://context/api/oauth/client_id')"/></client_id>
      </apim>

   </xsl:template>

</xsl:stylesheet>

