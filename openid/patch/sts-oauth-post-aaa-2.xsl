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

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:dp="http://www.datapower.com/extensions"
  xmlns:func="http://exslt.org/functions"
  xmlns:dpconfig="http://www.datapower.com/param/config"
  xmlns:jsonx="http://www.ibm.com/xmlns/prod/2009/jsonx"
  xmlns:regexp="http://exslt.org/regular-expressions"
  xmlns:apim="http://www.ibm.com/apimanagement"
  extension-element-prefixes="dp func dpconfig jsonx regexp apim">
  
  <xsl:import href="local:///isp/error_template.xsl"/>
  <xsl:import href="local:///isp/policy/apim.custom.xsl"/>
  
  <xsl:param name="dpconfig:action" select="''"/>
  <xsl:variable name="oauthPhase"  select="dp:variable('var://context/_apimgmt/oauth/phase')"/>
  
  <xsl:template match="/">
    <!--temp fix for bz47886-->
    <!--[todo] this can be removed -->
    <xsl:variable name="squote">'</xsl:variable>
    <xsl:variable name="CSPheader" select="concat('default-src ',$squote,'self',$squote, '; style-src ',$squote, 'unsafe-inline', $squote)"/> 
    <dp:set-http-response-header name="'Content-Security-Policy'" value="$CSPheader"/>

    <xsl:if test="$debug1">
      <xsl:message dp:priority="debug">
        <xsl:text>sts-oauth-post-aaa: action=</xsl:text>
        <xsl:value-of select="$dpconfig:action"/>
        <xsl:text> phase=</xsl:text>
        <xsl:value-of select="$oauthPhase"/>
      </xsl:message>
    </xsl:if>
    
    <!-- fail if we triggered an error from the Additional Processing XSLT -->
    <xsl:variable name="errorStatusCode" select="dp:variable('var://context/api/error-protocol-response')" />
    <xsl:if test="$debug1">
      <xsl:message dp:priority="debug">errorStatusCode = <xsl:value-of select="$errorStatusCode"/></xsl:message>
    </xsl:if>
    <xsl:if test="string-length($errorStatusCode) > 0">
      <xsl:message dp:priority="error" terminate="yes">
        <xsl:text>sts-oauth-post-aaa: detected error: </xsl:text>
        <xsl:value-of select="$errorStatusCode" />
      </xsl:message>
    </xsl:if>

    <xsl:choose>

    <!-- writes to the output context what phase of OAuth processing is being run in the STS -->
    <xsl:when test="$dpconfig:action = 'pre-output'">
      <oauth>
        <phase><xsl:element name="{$oauthPhase}"/></phase>
      </oauth>

      <xsl:variable name="location-header">
        <xsl:value-of select="dp:http-response-header('Location')"/>
      </xsl:variable>

      <!-- include metadata in the fragment for implicit grant type -->
      <xsl:if test="dp:variable('var://context/_apimgmt/requested-grant-type') = 'implicit' and 
                    starts-with(dp:http-response-header('x-dp-response-code'), '302') and 
                    string($location-header) != '' and 
                    contains($location-header,'#') and 
                    contains($location-header, 'access_token=') ">
        <xsl:variable name="metadata" select="string(dp:variable('var://context/api/oauth/metadata-for-payload'))"/>
        <xsl:if test="$metadata != ''">
          <xsl:variable name="new-location-header">
            <xsl:value-of select="concat($location-header, '&amp;metadata=',  dp:encode($metadata,'url'))"/>
          </xsl:variable>
          <dp:remove-http-response-header name="Location"/>
          <dp:set-http-response-header name="'Location'" value="$new-location-header"/>
        </xsl:if>
      </xsl:if>

      <xsl:call-template name="apim:output" />
    </xsl:when>

    <!-- 
     If there is a parsed JSON response from AAA, it tells we are probably responding the client with an 
     Access Token, plus information about this token's scope. Before the granted scope is returned to the
     client, we must remove the client_id information we appended to it
	 Also add metadata to the payload if specified.
     -->
    <xsl:when test="$dpconfig:action = 'post-output' and $oauthPhase = 'access_request'">
      <xsl:variable name="aaaOutput" select="dp:variable('var://context/aaa-output-jsonx')" />
      <xsl:if test="$aaaOutput/jsonx:object or $aaaOutput/jsonx:array">
        <xsl:variable name="newOutput">
          <xsl:apply-templates select="$aaaOutput" mode="post-output"/>
        </xsl:variable>
        <xsl:copy-of select="$newOutput" />
      </xsl:if>
      <xsl:call-template name="apim:output">
        <xsl:with-param name="mediaType" select="'application/json'" />
      </xsl:call-template>
    </xsl:when>
    </xsl:choose>

  </xsl:template>

  <!-- ==================================================================================================== -->

  <!-- Inject metadata into the response payload if made available, and only when access_token is present -->
  <xsl:template match="jsonx:string[@name = 'access_token']" mode="post-output">
    <xsl:copy-of select="."/>
      <xsl:if test="string(dp:variable('var://context/api/oauth/metadata-for-payload')) != ''">
        <xsl:element name="string" namespace="{namespace-uri()}">
          <xsl:attribute name="name">metadata</xsl:attribute>
          <xsl:value-of select="dp:variable('var://context/api/oauth/metadata-for-payload')"/>
        </xsl:element>
      </xsl:if>
  </xsl:template>

  <xsl:template match="jsonx:string[@name = 'error_description']/text()" mode="post-output">
     <xsl:variable name="errMsg" select="string(.)" />
     <xsl:value-of select="regexp:replace($errMsg, '\[[pc]-all.*\]', 'g', '')" />
  </xsl:template>
 
  <xsl:template match="@* | node()" mode="post-output">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="post-output"/>
    </xsl:copy>
  </xsl:template>


</xsl:stylesheet>
