<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                extension-element-prefixes="exslt">

<xsl:template name="fullname">
  <xsl:param name="nick" select="none"/>
  <xsl:param name="fallback" select="false"/>
  <xsl:param name="parent" select="false"/>
  <xsl:param name="rollcall" select='document("/proj/en/devrel/roll-call/userinfo.xml")'/>
  <xsl:if test='not($nick="none")'>
    <xsl:variable name="user" select='exslt:node-set($rollcall)//user[@username=translate($nick, "ABCDEFGHIJKLMNOPQRSTUVWXYZ","abcdefghijklmnopqrstuvwxyz")]'/>
    <xsl:choose>
      <xsl:when test='$user'>
        <xsl:for-each select='$user'>
          <xsl:if test='$parent="true"'><xsl:text>(</xsl:text></xsl:if>
	    <xsl:choose>
	      <xsl:when test="realname/@fullname">
	        <xsl:value-of select="realname/@fullname"/>
	      </xsl:when>
	      <xsl:otherwise>
                <xsl:value-of select="realname/firstname/text()"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="realname/familyname/text()"/>
	      </xsl:otherwise>
	    </xsl:choose>
          <xsl:if test='$parent="true"'><xsl:text>)</xsl:text></xsl:if>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test='$fallback="true"'>
          <xsl:if test='$parent="true"'><xsl:text>(</xsl:text></xsl:if>
          <xsl:value-of select="$nick"/>
          <xsl:if test='$parent="true"'><xsl:text>)</xsl:text></xsl:if>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>
</xsl:template>



<!-- Extract file name from a link -->
<xsl:template name="filename">
<xsl:param name="path"/>
  <xsl:choose>
    <!-- $path is a directory, assume file name is index.xml -->
    <xsl:when test="'/'=substring($path,string-length($path))">index.xml</xsl:when>
    <xsl:when test="contains($path, '/')">
      <xsl:call-template name="filename">
        <xsl:with-param name="path" select="substring-after($path, '/')"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$path"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


</xsl:stylesheet>
