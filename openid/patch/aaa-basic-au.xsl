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

<!-- hi -->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:apim="http://www.ibm.com/apimanagement"
    extension-element-prefixes="dp"
    exclude-result-prefixes="dp apim">

    <xsl:include href="aaa-ldap-lib.xsl"/>
    <xsl:include href="error_template.xsl" dp:ignore-multiple="yes"/>

    <xsl:variable name="logtype" select="'aaa'" />

    <!-- Get the Policy Properties from the properties context -->
    <xsl:include href="local:///isp/policy/apim.custom.xsl" />
    <xsl:variable name="properties" select="apim:policyProperties()" />

    <xsl:template match="/">
        <xsl:variable name="username" select="/identity/entry[@type='custom']/username" />
        <xsl:variable name="password" select="/identity/entry[@type='custom']/password" />

        <xsl:if test="$debug1">
          <xsl:message dp:type="apiconnect" dp:priority="debug">
            <xsl:text>custom-au: basic: </xsl:text>
            <xsl:value-of select="$username" />
            <xsl:text>/</xsl:text>
            <xsl:value-of select="/identity/entry[@type='custom']/api" />
          </xsl:message>
        </xsl:if>

        <xsl:choose>
          <xsl:when test="not($username) or string-length($username) = 0">
            <xsl:message dp:type="apiconnect" dp:priority="error">
              <xsl:text>custom-au: missing required user name</xsl:text>
            </xsl:message>
            <xsl:call-template name="error">
              <xsl:with-param name="code" select="'401'"/>
              <xsl:with-param name="reason" select="'Unauthorized'"/>
              <xsl:with-param name="challenge" select="'Basic'" />
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <!-- potential to use apim:setVariable -->
            <dp:set-variable name="'var://context/_apimgmt/authenticated-username'" value="string($username)"/>
          </xsl:otherwise>
        </xsl:choose>

        <xsl:if test="string-length($properties/authenticationURLsslProfile) > 0">
          <xsl:if test="$debug1">
            <xsl:message dp:type="apiconnect" dp:priority="debug">
              <xsl:text>custom-au: authenticationURLsslProfile :</xsl:text>
              <xsl:value-of select="$properties/authenticationURLsslProfile"/>
            </xsl:message>
          </xsl:if>
        </xsl:if>
        <xsl:if test="string-length($properties/sslProfile) > 0">
          <xsl:if test="$debug1">
            <xsl:message dp:type="apiconnect" dp:priority="debug">
              <xsl:text>custom-au: $sslProfile :</xsl:text>
              <xsl:value-of select="$properties/sslProfile"/>
            </xsl:message>
          </xsl:if>
        </xsl:if>
        <xsl:if test="not($password) or string-length($password) = 0">
          <xsl:message dp:type="apiconnect" dp:priority="error">
            <xsl:text>custom-au: missing required password</xsl:text>
          </xsl:message>
          <xsl:call-template name="error">
            <xsl:with-param name="code" select="'401'"/>
            <xsl:with-param name="reason" select="'Unauthorized'"/>
            <xsl:with-param name="challenge" select="'Basic'" />
          </xsl:call-template>
        </xsl:if>

       <!--select sslProfile-->
      <xsl:variable name="sslProfile">
        <xsl:choose>
          <xsl:when test="string-length($properties/authenticationURLsslProfile) &gt; 0">
            <xsl:value-of select="$properties/authenticationURLsslProfile/text()"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$properties/sslProfile/text()"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

        <!-- Basic Auth using Authentication URL -->
        <xsl:if test="string($properties/type) = 'authUrl' and string-length($properties/authenticationURL) &gt; 0">
            <xsl:call-template name="basic-auth-authurl">
                <xsl:with-param name="user"     select="$username"/>
                <xsl:with-param name="pass"     select="$password"/>
                <xsl:with-param name="sslProfile"     select="$sslProfile" />
                <xsl:with-param name="url"      select="$properties/authenticationURL/text()" />
            </xsl:call-template>
        </xsl:if>

        <!-- LDAP Authentication -->
        <xsl:if test="string($properties/type) = 'ldap' and string-length($properties/x-ibm-authentication-registry) &gt; 0">
            <xsl:call-template name="ldap-authenticate">
                <xsl:with-param name="user"      select="$username"/>
                <xsl:with-param name="pass"      select="$password"/>
                <xsl:with-param name="registry"  select="$properties/x-ibm-authentication-registry" />
                <xsl:with-param name="challenge" select="'Basic'" />
            </xsl:call-template>
        </xsl:if>

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

   </xsl:template>

</xsl:stylesheet>
