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
    xmlns:regexp="http://exslt.org/regular-expressions"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:func="http://exslt.org/functions"
    xmlns:apim="http://www.ibm.com/apimanagement"
    xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx"
    extension-element-prefixes="dp"
    exclude-result-prefixes="dp regexp apim json">

    <xsl:include href="error_template.xsl" dp:ignore-multiple="yes"/>
    <xsl:include href="webapi-sslprofile.xsl" />
    <xsl:include href="policy/apim.custom.xsl"/>

    <!-- retrieve Tenant and API information from context -->
    <xsl:variable name="tenant-policy" select="dp:variable('var://context/_apimgmt/tenant-policy')" />
    <!--<xsl:variable name="api-policy" select="dp:variable('var://context/_apimgmt/api-policy')" /> -->
    <xsl:variable name="startTime" select="dp:variable('var://service/time-elapsed')" />

   <!-- =====================================================================================
        LDAP AUTHENTICATION
        ===================================================================================== -->

    <xsl:template name="ldap-authenticate">
        <xsl:param name="user" />
        <xsl:param name="pass" />
        <xsl:param name="registry" />
        <xsl:param name="challenge" select="''" />

        <!-- test for non-empty user and password -->
        <xsl:if test="$user = '' or $pass = ''">
            <xsl:message dp:type="apiconnect" dp:priority="error">
              <xsl:text>custom-au: basic-auth-ldap FAILED: missing user or password</xsl:text>
            </xsl:message>
            <xsl:call-template name="error">
                <xsl:with-param name="code" select="'401'"/>
                <xsl:with-param name="reason" select="'Unauthorized'"/>
                <xsl:with-param name="challenge" select="$challenge" />
            </xsl:call-template>
        </xsl:if>

        <xsl:variable name="ldapProperties" select="apim:getRegistry($registry)/ldap"/>
        <xsl:variable name="ldapTimeout" select="'60'"/>
        <xsl:variable name="host" select="string($ldapProperties/property[@name='host'])"/>
        <xsl:variable name="port" select="string($ldapProperties/property[@name='port'])"/>
        <xsl:variable name="au-method" select="string($ldapProperties/property[@name='auth-method'])"/>
        <xsl:variable name="ldapVersion" select="string($ldapProperties/property[@name='protocol-version'])"/>

        <xsl:variable name="tlsEnabled" select="string($ldapProperties/property[@name='ssl']) = 'true'"/>
        <xsl:variable name="tlsProfile" select="string($ldapProperties/property[@name='tls-profile'])"/>
        <xsl:variable name="sslTemp">
          <xsl:call-template name="ldapSslProxyName">
            <xsl:with-param name="ldapProperties" select="$ldapProperties"/>
          </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="sslproxy" select="string($sslTemp)"/>

        <xsl:if test="$debug1">
          <xsl:message dp:type="apiconnect" dp:priority="debug">
            <xsl:value-of select="$registry"/>
            <xsl:copy-of select="$ldapProperties"/>
          </xsl:message>

          <xsl:message dp:type="apiconnect" dp:priority="debug">
            <xsl:text>ldap-authenticate: host: </xsl:text>
            <xsl:value-of select="$host" />
            <xsl:if test="$tlsEnabled">
              <xsl:text> tls: </xsl:text>
              <xsl:value-of select="$tlsProfile"/>
              <xsl:text>/</xsl:text>
              <xsl:value-of select="$sslproxy"/>
            </xsl:if>
            <xsl:text> option: </xsl:text>
            <xsl:value-of select="$au-method" />
          </xsl:message>
        </xsl:if>

        <xsl:choose>

          <xsl:when test="$au-method = 'searchDN'">
            <xsl:variable name="bindAdmin">
              <xsl:if test="string($ldapProperties/property[@name='authenticated-bind'])='true'">
                <dn><xsl:value-of select="$ldapProperties/property[@name='authenticated-bind-admin-dn']"/></dn>
                <pw><xsl:value-of select="$ldapProperties/property[@name='authenticated-bind-admin-password']"/></pw>
              </xsl:if>
            </xsl:variable>
            <xsl:variable name="bindAdminDn" select="string($bindAdmin/dn)"/>
            <xsl:variable name="bindAdminPw" select="string($bindAdmin/pw)"/>
            <xsl:variable name="BASE64_ENC_PREFIX" select="'!BASE64_ENC!_'" />
            <xsl:variable name="AES256" select="'http://www.w3.org/2001/04/xmlenc#aes256-cbc'" />
            <xsl:variable name="encryptedPW" select="$bindAdminPw" />
            <!-- Check if the password is encrypted, and decrypt if needed -->
            <xsl:variable name="decryptedPW">
              <xsl:choose>
                <xsl:when test="starts-with($encryptedPW, $BASE64_ENC_PREFIX)">
                  <xsl:value-of select="dp:decrypt-data($AES256, 'name:webapi-oauth-token-ss', substring-after($encryptedPW, $BASE64_ENC_PREFIX))" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$encryptedPW" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>

            <!-- Search DN -->
            <xsl:variable name="result">
             <xsl:call-template name="ldap-search">
               <xsl:with-param name="host"     select="$host"/>
               <xsl:with-param name="port"     select="$port"/>
               <xsl:with-param name="bindDN"   select="$bindAdminDn"/>
               <xsl:with-param name="bindPW"   select="$decryptedPW"/>
               <xsl:with-param name="targetDN" select="$ldapProperties/property[@name='search-dn-base']"/>
               <xsl:with-param name="attrName" select="'dn'"/>
               <xsl:with-param name="filter"   select="concat($ldapProperties/property[@name='search-dn-filter-prefix'],$user,$ldapProperties/property[@name='search-dn-filter-suffix'])"/>
               <xsl:with-param name="scope"    select="$ldapProperties/property[@name='search-dn-scope']"/>
               <xsl:with-param name="sslproxy" select="$sslproxy"/>
               <xsl:with-param name="version"  select="$ldapVersion"/>
               <xsl:with-param name="timeout"  select="number($ldapTimeout)"/>
             </xsl:call-template>
            </xsl:variable>

            <xsl:variable name="dn">
              <xsl:choose>
                <xsl:when test="contains($result/LDAP-search-results/result/DN,'\')">
                  <xsl:value-of select="regexp:replace($result/LDAP-search-results/result/DN,'\\','g','\')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$result/LDAP-search-results/result/DN"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>

            <!-- Bind to LDAP for Authentication -->
            <xsl:call-template name="ldap-bind">
              <xsl:with-param name="host"     select="$host"/>
              <xsl:with-param name="port"     select="$port"/>
              <xsl:with-param name="bindDN"   select="$dn"/>
              <xsl:with-param name="bindPW"   select="$pass"/>
              <xsl:with-param name="sslproxy" select="$sslproxy"/>
              <xsl:with-param name="version"  select="$ldapVersion"/>
              <xsl:with-param name="timeout"  select="number($ldapTimeout)"/>
              <xsl:with-param name="challenge" select="'Basic'" />
            </xsl:call-template>

            <xsl:if test="$policy-debug" >
              <xsl:call-template name="write-analytics-debug" >
                <xsl:with-param name="taskName" select="'LDAP Authenticate'" />
                <xsl:with-param name="endPoint" select="concat($host,':',$port)" />
                <xsl:with-param name="latency"  select="dp:variable('var://service/time-elapsed') - $startTime" />
                <xsl:with-param name="result" select="'OK'" />
              </xsl:call-template>
            </xsl:if>

            <authenticate-result>
              <user><xsl:value-of select="$user"/></user>
              <bind-dn><xsl:value-of select="$result/LDAP-search-results/result/DN" /></bind-dn>
              <az-base><xsl:value-of select="$result/LDAP-search-results/result/DN" /></az-base>
              <dp:set-variable name="'var://context/_apimgmt/authenticated-username'" value="string($result/LDAP-search-results/result/DN)"/>
            </authenticate-result>
          </xsl:when>

          <!--@@ BIND DN @@-->
          <xsl:when test="$au-method = 'bindDN'">
            <xsl:variable name="bindDN" select="concat($ldapProperties/property[@name='bind-prefix'],$user,$ldapProperties/property[@name='bind-suffix'])" />
            <xsl:call-template name="ldap-bind">
              <xsl:with-param name="host"     select="$host"/>
              <xsl:with-param name="port"     select="$port"/>
              <xsl:with-param name="bindDN"   select="$bindDN"/>
              <xsl:with-param name="bindPW"   select="$pass"/>
              <xsl:with-param name="sslproxy" select="$sslproxy"/>
              <xsl:with-param name="version"  select="$ldapVersion"/>
              <xsl:with-param name="timeout"  select="number($ldapTimeout)"/>
              <xsl:with-param name="challenge" select="'Basic'" />
            </xsl:call-template>

            <xsl:if test="$policy-debug" >
              <xsl:call-template name="write-analytics-debug" >
                <xsl:with-param name="taskName" select="'LDAP Authenticate'" />
                <xsl:with-param name="endPoint" select="concat($host,':',$port)" />
                <xsl:with-param name="latency"  select="dp:variable('var://service/time-elapsed') - $startTime" />
                <xsl:with-param name="result" select="'OK'" />
              </xsl:call-template>
            </xsl:if>

            <authenticate-result>
              <user><xsl:value-of select="$user"/></user>
              <bind-dn><xsl:value-of select="$bindDN" /></bind-dn>
              <az-base><xsl:value-of select="$bindDN" /></az-base>
              <az-scope>base</az-scope>
              <dp:set-variable name="'var://context/_apimgmt/authenticated-username'" value="string($bindDN)"/>
            </authenticate-result>
            <username><xsl:value-of select="$user"/></username>

        </xsl:when>

        <xsl:when test="$au-method = 'bindUPN'">
            <!--
            Compose UPN (not a valid DN, but this is MSAD)
            Use a "Search" call to not only authenticate, but also retrieve the defaultNamingContext that
            will be needed in case we need to check for group membership for authorization
            -->
            <xsl:variable name="bindDN" select="concat($user,$ldapProperties/property[@name='bind-suffix'])" />
            <xsl:variable name="result">
             <xsl:call-template name="ldap-search">
               <xsl:with-param name="host"     select="$host"/>
               <xsl:with-param name="port"     select="$port"/>
               <xsl:with-param name="bindDN"   select="$bindDN"/>
               <xsl:with-param name="bindPW"   select="$pass"/>
               <xsl:with-param name="targetDN" select="''"/>
               <xsl:with-param name="attrName" select="'defaultNamingContext'"/>
               <xsl:with-param name="filter"   select="'(objectClass=*)'"/>
               <xsl:with-param name="scope"    select="'base'"/>
               <xsl:with-param name="sslproxy" select="$sslproxy"/>
               <xsl:with-param name="version"  select="$ldapVersion"/>
               <xsl:with-param name="timeout"  select="number($ldapTimeout)"/>
               <xsl:with-param name="challenge" select="'Basic'" />
             </xsl:call-template>
            </xsl:variable>

            <xsl:if test="$policy-debug" >
              <xsl:call-template name="write-analytics-debug" >
                <xsl:with-param name="taskName" select="'LDAP Authenticate'" />
                <xsl:with-param name="endPoint" select="concat($host,':',$port)" />
                <xsl:with-param name="latency"  select="dp:variable('var://service/time-elapsed') - $startTime" />
                <xsl:with-param name="result" select="'OK'" />
              </xsl:call-template>
            </xsl:if>

            <authenticate-result>
              <user><xsl:value-of select="$user"/></user>
              <bind-dn><xsl:value-of select="$bindDN" /></bind-dn>
              <az-base><xsl:value-of select="$result/LDAP-search-results/result/attribute-value[@name='defaultNamingContext']" /></az-base>
              <az-scope>sub</az-scope>
              <az-filter-prefix>(userPrincipalName=<xsl:value-of select="$bindDN"/>)</az-filter-prefix>
              <dp:set-variable name="'var://context/_apimgmt/authenticated-username'" value="string($bindDN)"/>
            </authenticate-result>
            <username><xsl:value-of select="$user"/></username>

        </xsl:when>

        <xsl:otherwise>

            <xsl:if test="$policy-debug" >
              <xsl:call-template name="write-analytics-debug" >
                <xsl:with-param name="taskName" select="'LDAP Authenticate'" />
                <xsl:with-param name="endPoint" select="concat($host,':',$port)" />
                <xsl:with-param name="latency"  select="dp:variable('var://service/time-elapsed') - $startTime" />
                <xsl:with-param name="result" select="'Failed'" />
              </xsl:call-template>
            </xsl:if>

           <xsl:message dp:type="apiconnect" dp:priority="error">custom-au: invalid LDAP method</xsl:message>
            <xsl:call-template name="error">
                <xsl:with-param name="code" select="'401'"/>
                <xsl:with-param name="reason" select="'Unauthorized'"/>
                <xsl:with-param name="challenge" select="$challenge" />
            </xsl:call-template>
        </xsl:otherwise>
        </xsl:choose>

    </xsl:template>


   <!-- =====================================================================================
        LDAP AUTHORIZATION - Check membership in Group
        ===================================================================================== -->

    <xsl:template name="ldap-authorize">
        <xsl:param name="au-container"/>
        <xsl:param name="registry"/>
        <xsl:variable name="au-result" select="$au-container/mapped-credentials/entry[@type='custom']" />
        <xsl:variable name="ldapProperties" select="apim:getRegistry($registry)/ldap"/>
        <xsl:variable name="ldapTimeout" select="'60'"/>
        <xsl:variable name="host" select="string($ldapProperties/property[@name='host'])"/>
        <xsl:variable name="port" select="string($ldapProperties/property[@name='port'])"/>
        <xsl:variable name="au-method" select="string($ldapProperties/property[@name='auth-method'])"/>
        <xsl:variable name="ldapVersion" select="string($ldapProperties/property[@name='protocol-version'])"/>
        <xsl:variable name="sslTemp">
          <xsl:call-template name="ldapSslProxyName">
            <xsl:with-param name="ldapProperties" select="$ldapProperties"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="sslproxy" select="string($sslTemp)"/>
        <xsl:variable name="groupAuthMethod" select="$ldapProperties/property[@name='group-auth-method']"/>
        <xsl:variable name="dynGroupFilter" select="$ldapProperties/property[@name='dynamic-group-filter']"/>

        <xsl:if test="$debug1">
          <xsl:message dp:type="apiconnect" dp:priority="debug">
            <xsl:text>ldap-authorize: group-auth-method: </xsl:text>
            <xsl:value-of select="$groupAuthMethod" />
            <xsl:if test="$groupAuthMethod = 'dynamicAuth'">
              <xsl:text> filter=</xsl:text>
              <xsl:value-of select="$dynGroupFilter"/>
            </xsl:if>
          </xsl:message>
        </xsl:if>

        <xsl:variable name="bindPW">
          <xsl:choose>
            <xsl:when test="string-length($au-container/identity/entry[@type='custom']/password) > 0">
              <xsl:value-of select="$au-container/identity/entry[@type='custom']/password" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="dp:auth-info('basic-auth-password')" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:choose>
          <!-- Authentication failed, decline authorization -->
          <xsl:when test="$au-container/mapped-credentials/@au-success != 'true'">
            <xsl:if test="$policy-debug" >
              <xsl:call-template name="write-analytics-debug" >
                <xsl:with-param name="taskName" select="'LDAP Authorize'" />
                <xsl:with-param name="endPoint" select="concat($host,':',$port)" />
                <xsl:with-param name="latency"  select="dp:variable('var://service/time-elapsed') - $startTime" />
                <xsl:with-param name="result" select="'Failed'" />
              </xsl:call-template>
            </xsl:if>
            <declined>authentication failed</declined>
          </xsl:when>

          <!-- Missing LDAP information for authorization, decline due to internal error -->
          <xsl:when test="count($ldapProperties) = 0 ">
            <xsl:if test="$policy-debug" >
              <xsl:call-template name="write-analytics-debug" >
                <xsl:with-param name="taskName" select="'LDAP Authorize'" />
                <xsl:with-param name="endPoint" select="concat($host,':',$port)" />
                <xsl:with-param name="latency"  select="dp:variable('var://service/time-elapsed') - $startTime" />
                <xsl:with-param name="result" select="'Failed'" />
              </xsl:call-template>
            </xsl:if>
            <declined>internal error, LDAP connection information missing</declined>
          </xsl:when>

          <!-- Authentication successful, authorize with LDAP dynamic group filter -->
          <xsl:when test="$groupAuthMethod = 'dynamicAuth'">
            <xsl:variable name="filter">
              <xsl:choose>
                <xsl:when test="$au-result/authenticate-result/az-filter-prefix">
                  <xsl:value-of select="concat('(&amp;', $au-result/authenticate-result/az-filter-prefix, $dynGroupFilter, ')')" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$dynGroupFilter" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>

            <xsl:variable name="search-result">
              <xsl:call-template name="ldap-search">
                <xsl:with-param name="host"     select="$host"/>
                <xsl:with-param name="port"     select="$port"/>
                <xsl:with-param name="bindDN"   select="$au-result/authenticate-result/bind-dn"/>
                <xsl:with-param name="bindPW"   select="$bindPW" />
                <xsl:with-param name="targetDN" select="$au-result/authenticate-result/az-base"/>
                <xsl:with-param name="attrName" select="'dn'"/>
                <xsl:with-param name="filter"   select="$filter"/>
                <xsl:with-param name="scope"    select="$au-result/authenticate-result/az-scope"/>
                <xsl:with-param name="sslproxy" select="$sslproxy"/>
                <xsl:with-param name="version"  select="$ldapVersion"/>
                <xsl:with-param name="timeout"  select="number($ldapTimeout)"/>
                <xsl:with-param name="challenge" select="'Basic'" />
              </xsl:call-template>
            </xsl:variable>

            <xsl:if test="$policy-debug" >
              <xsl:call-template name="write-analytics-debug" >
                <xsl:with-param name="taskName" select="'LDAP Authorize'" />
                <xsl:with-param name="endPoint" select="concat($host,':',$port)" />
                <xsl:with-param name="latency"  select="dp:variable('var://service/time-elapsed') - $startTime" />
                <xsl:with-param name="result" select="'OK'" />
              </xsl:call-template>
            </xsl:if>

            <approved>LDAP dynamic group membership verified</approved>
          </xsl:when>

          <!-- Authentication successful, authorize with LDAP static group filter -->
          <xsl:when test="$groupAuthMethod = 'staticAuth'">
            <xsl:variable name="user">
              <xsl:value-of select="$au-result/authenticate-result/bind-dn" />
            </xsl:variable>
            <xsl:variable name="search-result">
              <xsl:call-template name="ldap-search">
                <xsl:with-param name="host"     select="$host"/>
                <xsl:with-param name="port"     select="$port"/>
                <xsl:with-param name="bindDN"   select="$ldapProperties/property[@name='authenticated-bind-admin-dn']"/>
                <xsl:with-param name="bindPW"   select="$ldapProperties/property[@name='authenticated-bind-admin-password']"/>
                <xsl:with-param name="targetDN" select="$ldapProperties/property[@name='static-group-dn']"/>
                <xsl:with-param name="attrName" select="'dn'"/>
                <xsl:with-param name="filter"   select="concat($ldapProperties/property[@name='static-group-filter-prefix'],$user,$ldapProperties/property[@name='static-group-filter-suffix'])"/>
                <xsl:with-param name="scope"    select="$ldapProperties/property[@name='static-group-scope']"/>
                <xsl:with-param name="sslproxy" select="$sslproxy"/>
                <xsl:with-param name="version"  select="$ldapVersion"/>
                <xsl:with-param name="timeout"  select="number($ldapTimeout)"/>
                <xsl:with-param name="challenge" select="'Basic'" />
              </xsl:call-template>
            </xsl:variable>

            <xsl:if test="$policy-debug" >
              <xsl:call-template name="write-analytics-debug" >
                <xsl:with-param name="taskName" select="'LDAP Authorize'" />
                <xsl:with-param name="endPoint" select="concat($host,':',$port)" />
                <xsl:with-param name="latency"  select="dp:variable('var://service/time-elapsed') - $startTime" />
                <xsl:with-param name="result" select="'OK'" />
              </xsl:call-template>
            </xsl:if>

            <approved>LDAP group membership verified</approved>
          </xsl:when>

          <xsl:when test="not($groupAuthMethod = 'none')">
           <declined>internal error, group authorization method invalid: <xsl:value-of select="$groupAuthMethod"/></declined>
          </xsl:when>

          <!-- No authorization work is required, approved -->
          <xsl:otherwise>
            <xsl:if test="$policy-debug" >
              <xsl:call-template name="write-analytics-debug" >
                <xsl:with-param name="taskName" select="'LDAP Authorize'" />
                <xsl:with-param name="endPoint" select="concat($host,':',$port)" />
                <xsl:with-param name="latency"  select="dp:variable('var://service/time-elapsed') - $startTime" />
                <xsl:with-param name="result" select="'OK'" />
              </xsl:call-template>
            </xsl:if>

            <approved>LDAP group membership verification not required.</approved>
          </xsl:otherwise>

        </xsl:choose>

    </xsl:template>


    <!-- =====================================================================================
         LDAP BIND
         ===================================================================================== -->

    <xsl:template name="ldap-bind">
        <xsl:param name="host"/>
        <xsl:param name="port"/>
        <xsl:param name="bindDN"/>
        <xsl:param name="bindPW"/>
        <xsl:param name="sslproxy" select="''"/>
        <xsl:param name="lbgroup"  select="''"/>
        <xsl:param name="sslcert"  select="''"/>
        <xsl:param name="version"/>
        <xsl:param name="timeout"/>
        <xsl:param name="challenge" select="''" />


        <xsl:variable name="fixedVersion">
           <xsl:choose>
                 <xsl:when test="$version='2'">
                      <xsl:text>v2</xsl:text>
                 </xsl:when>
                 <xsl:when test="$version='3'">
                      <xsl:text>v3</xsl:text>
                 </xsl:when>
                 <xsl:otherwise>
                      <xsl:value-of select="$version"/>
                 </xsl:otherwise>
           </xsl:choose>
        </xsl:variable>

        <xsl:if test="$debug &gt; 0">
           <xsl:message dp:type="apiconnect" dp:priority="debug">
             <xsl:text>ldap-bind: bind dn: </xsl:text><xsl:value-of select="$bindDN"/>
           </xsl:message>
           <xsl:message dp:type="apiconnect" dp:priority="debug">
             <xsl:text>ldap-bind: bindRequest version: </xsl:text><xsl:value-of select="$fixedVersion"/>
           </xsl:message>
           <xsl:message dp:type="apiconnect" dp:priority="debug">
             <xsl:text>ldap-bind: bindRequest timeout: </xsl:text><xsl:value-of select="$timeout"/>
           </xsl:message>
        </xsl:if>
        <xsl:variable name="server" select="concat($host,':',$port)"/>
        <xsl:variable name="result" select="dp:ldap-authen($bindDN,$bindPW,$server,$sslproxy,$lbgroup,$sslcert,$fixedVersion,$timeout)"/>

        <xsl:if test="$policy-debug" >
          <xsl:variable name="analytics-debug-input-parameters">
              <xsl:element name="json:string">
                <xsl:attribute name="name">
                  <xsl:text>ldap-version</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="$fixedVersion"/>
              </xsl:element>
              <xsl:element name="json:string">
                <xsl:attribute name="name">
                  <xsl:text>ldap-bindDN</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="$bindDN"/>
              </xsl:element>
              <xsl:if test="not($bindPW = '')" >
                <xsl:element name="json:string">
                  <xsl:attribute name="name">
                    <xsl:text>ldap-bindPW</xsl:text>
                  </xsl:attribute>
                  <xsl:text>**********</xsl:text>
                </xsl:element>
              </xsl:if>
          </xsl:variable>
          <xsl:variable name="authResult">
          <xsl:choose>
            <xsl:when test = "$result">OK</xsl:when>
            <xsl:otherwise>Failed</xsl:otherwise>
          </xsl:choose>
          </xsl:variable>

          <xsl:call-template name="write-analytics-debug" >
            <xsl:with-param name="taskName" select="'LDAP Bind'" />
            <xsl:with-param name="endPoint" select="$server" />
            <xsl:with-param name="latency"  select="dp:variable('var://service/time-elapsed') - $startTime" />
            <xsl:with-param name="result" select="$authResult" />
            <xsl:with-param name="inputData" >
              <xsl:element name="input">
                <xsl:element name="headers"/>
                <xsl:element name="parameters">
                  <xsl:copy-of select="$analytics-debug-input-parameters" />
                </xsl:element>
                <xsl:element name="body"/>
              </xsl:element>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>

        <xsl:choose>
            <xsl:when test="$result"/>
            <xsl:otherwise>
                <xsl:message dp:type="apiconnect" dp:priority="error">
                  <xsl:text>ldap-bind: bind failed: dn </xsl:text><xsl:value-of select="$bindDN"/>
                </xsl:message>
                <xsl:call-template name="error">
                    <xsl:with-param name="code" select="'401'"/>
                    <xsl:with-param name="reason" select="'Unauthorized'"/>
                    <xsl:with-param name="challenge" select="$challenge" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
   </xsl:template>


    <!-- =====================================================================================
         LDAP SEARCH
         ===================================================================================== -->

    <xsl:template name="ldap-search">
        <xsl:param name="host"/>
        <xsl:param name="port"/>
        <xsl:param name="bindDN"/>
        <xsl:param name="bindPW"/>
        <xsl:param name="targetDN"/>
        <xsl:param name="attrName"/>
        <xsl:param name="filter"/>
        <xsl:param name="scope"/>
        <xsl:param name="sslproxy" select="''"/>
        <xsl:param name="lbgroup"  select="''"/>
        <xsl:param name="version"/>
        <xsl:param name="timeout"/>
        <xsl:param name="challenge" select="''" />


        <xsl:variable name="fixedVersion">
           <xsl:choose>
                 <xsl:when test="$version='2'">
                      <xsl:text>v2</xsl:text>
                 </xsl:when>
                 <xsl:when test="$version='3'">
                      <xsl:text>v3</xsl:text>
                 </xsl:when>
                 <xsl:otherwise>
                      <xsl:value-of select="$version"/>
                 </xsl:otherwise>
           </xsl:choose>
        </xsl:variable>

        <xsl:if test="$debug1">
          <xsl:message dp:type="apiconnect" dp:priority="debug">
            <xsl:text>ldap-search: </xsl:text>
            <xsl:value-of select="$targetDN" />
            <xsl:text> filter: </xsl:text>
            <xsl:value-of select="$filter" />
          </xsl:message>

          <xsl:message dp:type="apiconnect" dp:priority="debug">
            <xsl:text>ldap-search: bindDN: </xsl:text>
            <xsl:value-of select="$bindDN" />
          </xsl:message>
          <!--@@ Do not print the Password, ever! @@-->
          <xsl:if test="false">
            <xsl:message dp:type="apiconnect" dp:priority="debug">
              <xsl:text>ldap-search: bindPW: </xsl:text>
            </xsl:message>
          </xsl:if>
        </xsl:if>

        <xsl:variable name="server" select="concat($host,':',$port)"/>
        <xsl:variable name="result"
             select="dp:ldap-search($host,$port,$bindDN,$bindPW,$targetDN,$attrName,$filter,$scope,$sslproxy,$lbgroup,$fixedVersion,$timeout)"/>

        <xsl:if test="$debug &gt; 0">
          <xsl:message dp:type="apiconnect" dp:priority="debug">
            <xsl:value-of select="'ldap-search: result: '" /><xsl:copy-of select="$result"/>
          </xsl:message>
        </xsl:if>

        <xsl:if test="$policy-debug" >
          <xsl:variable name="analytics-debug-input-parameters">
              <xsl:element name="json:string">
                <xsl:attribute name="name">
                  <xsl:text>ldap-version</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="$fixedVersion"/>
              </xsl:element>
              <xsl:element name="json:string">
                <xsl:attribute name="name">
                  <xsl:text>ldap-bindDN</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="$bindDN"/>
              </xsl:element>
              <xsl:element name="json:string">
                <xsl:attribute name="name">
                  <xsl:text>ldap-targetDN</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="$targetDN"/>
              </xsl:element>
              <xsl:element name="json:string">
                <xsl:attribute name="name">
                  <xsl:text>ldap-filter</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="$filter"/>
              </xsl:element>
              <xsl:element name="json:string">
                <xsl:attribute name="name">
                  <xsl:text>ldap-scope</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="$scope"/>
              </xsl:element>
              <xsl:if test="not($bindPW = '')" >
                <xsl:element name="json:string">
                  <xsl:attribute name="name">
                    <xsl:text>ldap-bindPW</xsl:text>
                  </xsl:attribute>
                  <xsl:text>**********</xsl:text>
                </xsl:element>
              </xsl:if>
          </xsl:variable>
          <xsl:variable name="analytics-debug-output-parameters">
            <xsl:element name="json:string">
              <xsl:attribute name="name">
                <xsl:text>ldap-search-result</xsl:text>
              </xsl:attribute>
              <xsl:value-of select="$result/LDAP-search-results/result"/>
            </xsl:element>
          </xsl:variable>
          <xsl:variable name="authResult">
          <xsl:choose>
            <xsl:when test = "$result/LDAP-search-error or (count($result/LDAP-search-results/result)!=1)">FAILED</xsl:when>
            <xsl:otherwise>OK</xsl:otherwise>
          </xsl:choose>
          </xsl:variable>

          <xsl:call-template name="write-analytics-debug" >
            <xsl:with-param name="taskName" select="'LDAP Search'" />
            <xsl:with-param name="endPoint" select="$server" />
            <xsl:with-param name="latency"  select="dp:variable('var://service/time-elapsed') - $startTime" />
            <xsl:with-param name="result" select="$authResult" />
            <xsl:with-param name="inputData" >
              <xsl:element name="input">
                <xsl:element name="headers"/>
                <xsl:element name="parameters">
                  <xsl:copy-of select="$analytics-debug-input-parameters" />
                </xsl:element>
                <xsl:element name="body"/>
              </xsl:element>
            </xsl:with-param>
            <xsl:with-param name="outputData" >
              <xsl:element name="output">
                <xsl:element name="headers"/>
                <xsl:element name="parameters">
                  <xsl:copy-of select="$analytics-debug-output-parameters" />
                </xsl:element>
                <xsl:element name="body"/>
              </xsl:element>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>

        <xsl:if test="$result/LDAP-search-error">
            <xsl:message dp:type="apiconnect" dp:priority="error">custom: ldap-search FAILED <xsl:copy-of select="$result/LDAP-search-error"/></xsl:message>
            <xsl:call-template name="error">
                <xsl:with-param name="code" select="'401'"/>
                <xsl:with-param name="reason" select="'Unauthorized'"/>
                <xsl:with-param name="challenge" select="$challenge" />
            </xsl:call-template>
        </xsl:if>
        <xsl:if test="count($result/LDAP-search-results/result)!=1">
            <xsl:message dp:type="apiconnect" dp:priority="error">custom: basic-auth-ldap FAILED <xsl:copy-of select="$result/LDAP-search-results"/></xsl:message>
            <xsl:call-template name="error">
                <xsl:with-param name="code" select="'401'"/>
                <xsl:with-param name="reason" select="'Unauthorized'"/>
                <xsl:with-param name="challenge" select="$challenge" />
            </xsl:call-template>
        </xsl:if>
        <!-- return good result -->
        <xsl:copy-of select="$result"/>
        <xsl:if test="$debug &gt; 0">
          <xsl:message dp:type="apiconnect" dp:priority="debug">custom: ldap-search successful <xsl:value-of select="$filter"/></xsl:message>
        </xsl:if>
    </xsl:template>

   <!-- =====================================================================================
        BASIC AUTHENTICATION WITH AUTHENTICATION URL
        ===================================================================================== -->

    <xsl:template name="basic-auth-authurl">
        <xsl:param name="user" />
        <xsl:param name="pass" />
        <xsl:param name="sslProfile" />
        <xsl:param name="url"  />
        <xsl:param name="isPasswordDigest" select="false()" />

        <xsl:variable name="basicAuthCredentials" select="concat($user,':',$pass)"/>

        <xsl:variable name="http-request-header">
          <header name="Authorization">
            <xsl:text>Basic </xsl:text>
            <xsl:value-of select="dp:encode($basicAuthCredentials,'base-64')"/>
          </header>
          <xsl:if test="$isPasswordDigest">
            <header name="X-IBM-PasswordType">
              <text>digest</text>
            </header>
          </xsl:if>
          <xsl:copy-of select="apim:GetOriginalRequestInfo()"/>
        </xsl:variable>

        <xsl:if test="$debug1">
          <xsl:message dp:type="apiconnect" dp:priority="debug">
              <xsl:text>Authentication URL: </xsl:text>
              <xsl:value-of select="$url" />
          </xsl:message>

         <xsl:message dp:type="apiconnect" dp:priority="debug">
           <xsl:text>SSL Profile: </xsl:text>
           <xsl:value-of select="$sslProfile" />
         </xsl:message>
       </xsl:if>

       <xsl:variable name="sslproxy" >
          <xsl:variable name="customsslprofile">
            <xsl:choose>
              <xsl:when test="string-length($sslProfile) > 0">
                <!--
                  getTLSProfileObjName() returns client: prefixed profile
                  prune it here because the logic below attempts to compute the
                  raw name and then prefixes the end result with client:
                 -->
                <xsl:value-of select="substring-after(apim:getTLSProfileObjName($sslProfile), 'client:')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="apim:getSSLProxyProfile(dp:variable('var://context/_apimgmt/ten-node')/tenant/@org, dp:variable('var://context/_apimgmt/ten-node')/tenant/@env, $url)"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="not($customsslprofile = '')">
              <xsl:value-of select="$customsslprofile" />
            </xsl:when>
            <xsl:otherwise>api-sslcli-all</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="basic-auth-response">
            <dp:url-open target="{$url}"
                         http-headers="$http-request-header"
                         http-method="get" response="responsecode-ignore"
                         ssl-proxy="{concat('client:', $sslproxy)}"
            />
        </xsl:variable>

        <xsl:if test="$debug &gt; 0">
            <xsl:message dp:type="apiconnect" dp:priority="debug">
                <xsl:text>custom-au: basic-auth-response: </xsl:text>
                <xsl:copy-of select="$basic-auth-response"/>
            </xsl:message>
        </xsl:if>

        <xsl:if test="$policy-debug" >
          <xsl:variable name="analytics-debug-input-parameters">
              <xsl:element name="json:string">
                <xsl:attribute name="name">
                  <xsl:text>user</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="$user"/>
              </xsl:element>
              <xsl:if test="not($pass = '')" >
                <xsl:element name="json:string">
                  <xsl:attribute name="name">
                    <xsl:text>pass</xsl:text>
                  </xsl:attribute>
                  <xsl:text>**********</xsl:text>
                </xsl:element>
              </xsl:if>
          </xsl:variable>
          <xsl:variable name="authResult">
          <xsl:choose>
            <xsl:when test="starts-with($basic-auth-response/url-open/responsecode, '2')">Authenticated</xsl:when>
            <xsl:otherwise>Authentication Failure</xsl:otherwise>
          </xsl:choose>
          </xsl:variable>

          <xsl:call-template name="write-analytics-debug" >
            <xsl:with-param name="taskName" select="'Basic Auth URL'" />
            <xsl:with-param name="endPoint" select="$url" />
            <xsl:with-param name="latency"  select="dp:variable('var://service/time-elapsed') - $startTime" />
            <xsl:with-param name="result" select="$authResult" />
            <xsl:with-param name="inputData" >
              <xsl:element name="input">
                <xsl:element name="headers"/>
                <xsl:element name="parameters">
                  <xsl:copy-of select="$analytics-debug-input-parameters" />
                </xsl:element>
                <xsl:element name="body"/>
              </xsl:element>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>

        <xsl:choose>
          <xsl:when test = "$basic-auth-response/url-open/responsecode = '200'">
            <xsl:if test="$debug1">
              <xsl:message dp:type="apiconnect" dp:priority="debug">
                <xsl:text>custom-au: Authentication-URL succeeded</xsl:text>
              </xsl:message>
            </xsl:if>
            <xsl:variable name="oauth-metadata-for-accesstoken" select="$basic-auth-response/url-open/headers/header/@*[local-name()='name' and translate(., 'API-OAUTH-METADATA-FOR-ACCESSTOKEN', 'api-oauth-metadata-for-accesstoken') = 'api-oauth-metadata-for-accesstoken']/.."/>
            <xsl:variable name="oauth-metadata-for-payload" select="$basic-auth-response/url-open/headers/header/@*[local-name()='name' and translate(., 'API-OAUTH-METADATA-FOR-PAYLOAD', 'api-oauth-metadata-for-payload') = 'api-oauth-metadata-for-payload']/.."/>
            <xsl:variable name="authenticated-credential" select="$basic-auth-response/url-open/headers/header/@*[local-name()='name' and translate(., 'API-AUTHENTICATED-CREDENTIAL', 'api-authenticated-credential') = 'api-authenticated-credential']/.."/>
            <authenticate-result>
              <xsl:choose>
                <xsl:when test="$authenticated-credential/text() != ''">
                  <user>
                    <xsl:attribute name="verified-user"><xsl:value-of select="$user"/></xsl:attribute>
                    <xsl:value-of select="$authenticated-credential/text()"/>
                    <dp:set-variable name="'var://context/_apimgmt/authenticated-username'" value="string($authenticated-credential)" />
                  </user>
                </xsl:when>
                <xsl:otherwise>
                  <user><xsl:value-of select="$user"/></user>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:if test="$oauth-metadata-for-accesstoken/text() != ''">
                <oauth-metadata-for-accesstoken><xsl:value-of select="$oauth-metadata-for-accesstoken"/></oauth-metadata-for-accesstoken>
                <xsl:message dp:type="apiconnect" dp:priority="debug">
                  <xsl:value-of select="'From Auth URL - metadata-for-access-token: '" /><xsl:value-of select="$oauth-metadata-for-accesstoken"/>
                </xsl:message>
              </xsl:if>
              <xsl:if test="$oauth-metadata-for-payload/text() != ''">
                <oauth-metadata-for-payload><xsl:value-of select="$oauth-metadata-for-payload"/></oauth-metadata-for-payload>
                <xsl:message dp:type="apiconnect" dp:priority="debug">
                  <xsl:value-of select="'From Auth URL - metadata-for-payload: '" /><xsl:value-of select="$oauth-metadata-for-payload"/>
                </xsl:message>
              </xsl:if>
            </authenticate-result>
            <!-- username -->
            <xsl:choose>
              <xsl:when test="$authenticated-credential/text() != ''">
                <username><xsl:value-of select="$authenticated-credential/text()"/></username>
              </xsl:when>
              <xsl:otherwise>
                <username><xsl:value-of select="$user"/></username>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message dp:type="apiconnect" dp:priority="error">
              <xsl:text>custom-au: Authentication-URL failed</xsl:text>
            </xsl:message>
            <xsl:call-template name="error">
              <xsl:with-param name="code" select="'401'"/>
              <xsl:with-param name="reason" select="'Unauthorized'"/>
              <xsl:with-param name="challenge" select="'Basic'" />
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <!--  This function is used to build custom request headers that are common to be sent to both authen url and metadata-url -->
    <func:function name="apim:GetOriginalRequestInfo">
      <func:result>
        <!-- pass in original request information, including header with X-, Cookie, query & body -->
        <!-- notice that this requires internal knowledge of the context variable name,
               this means if the input context variable name is changed, this logic
               needs to be updated to reflect that
          -->
        <xsl:variable name="inputvar" select="dp:variable('var://context/aaa-input')"/>
        <header name="X-URI-in">
          <xsl:value-of select="$inputvar/request/url"/>
        </header>

        <xsl:variable name="inmethod" select="dp:http-request-method()"/>

        <header name="X-METHOD-in">
          <xsl:value-of select="$inmethod"/>
        </header>

        <!-- information in the body needs to loop thru -->
        <xsl:if test="$inmethod = 'POST'">
          <xsl:variable name="rebuild-with-query-body">
            <xsl:text/>
            <xsl:for-each select="$inputvar/request/args[@src='body']/arg">
              <xsl:if test="position() &gt; 1">
                <xsl:text>&amp;</xsl:text>
              </xsl:if>
              <xsl:choose>
                <xsl:when test="not(text())">
                  <xsl:value-of select="@name"/>
                </xsl:when>
                <xsl:when test="contains(translate(@name, 'SECRT', 'secrt'),'secret') or 
                  contains(translate(@name, 'PASWORD', 'pasword'), 'password')">
                  <xsl:value-of select="concat(@name, '=xxxxxxxx')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="concat(@name, '=', text())"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </xsl:variable>
          <xsl:if test="$rebuild-with-query-body != ''">
            <header name="X-POST-Body-in">
              <xsl:value-of select="$rebuild-with-query-body"/>
            </header>
          </xsl:if>
        </xsl:if>

        <!-- original request header with X & Cookie -->
        <xsl:for-each select="dp:variable('var://context/_apimgmt/ana/request-headers')/header-array/header-element">
          <xsl:variable name="header-lowercase" select="translate(header-name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
          <xsl:choose>
            <xsl:when test="starts-with($header-lowercase, 'x-') and
              not(contains($header-lowercase, 'secret')) and
              not(contains($header-lowercase, 'password'))">
              <header name="{concat('X-', header-name)}">
                <xsl:value-of select="header"/>
              </header>
            </xsl:when>
            <xsl:when test="header-name = 'Cookie'">
              <header name="X-Cookie">
                <xsl:value-of select="header"/>
              </header>
            </xsl:when>
            <xsl:otherwise/>
          </xsl:choose>
        </xsl:for-each>
      </func:result>
    </func:function>

    <xsl:template name="ldapSslProxyName">
      <xsl:param name="ldapProperties"/>
      <xsl:variable name="tlsEnabled" select="string($ldapProperties/property[@name='ssl']) = 'true'"/>
      <xsl:variable name="tlsProfile" select="string($ldapProperties/property[@name='tls-profile'])"/>
      <xsl:if test="$tlsEnabled">
        <xsl:choose>
          <xsl:when test="string-length($tlsProfile)>0">
            <xsl:value-of select="apim:getTLSProfileObjName($tlsProfile)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="'api-sslcli-ldap'"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
    </xsl:template>

</xsl:stylesheet>

