<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:exslt="http://exslt.org/common"
                xmlns:func="http://exslt.org/functions"
                xmlns:dyn="http://exslt.org/dynamic"
                xmlns:str="http://exslt.org/strings"

                extension-element-prefixes="exslt func dyn str" >

<xsl:template match="/menu/group">
 <xsl:if test="@title and @top='N'">
  <xsl:value-of select="@title"/><br/>
 </xsl:if>
 <xsl:apply-templates/>
</xsl:template>

<xsl:template match="/menu/group/item">
 <xsl:variable name="www"><xsl:if test="$httphost!='www'">http://www.gentoo.org</xsl:if></xsl:variable>

 <xsl:variable name="href">
  <xsl:choose>
   <xsl:when test="not(starts-with(@href, '/'))">
    <xsl:value-of select="@href"/>
   </xsl:when>
   <xsl:when test="string-length($glang)=0 or $glang='en'">
    <xsl:value-of select="concat($www, @href)"/>
   </xsl:when>
   <xsl:when test="(substring(@href,string-length(@href))='/') and not(document(concat(substring-before(@href,'/en/'), '/', $glang, '/', substring-after(@href,'/en/'), 'index.xml'))/missing)">
    <xsl:value-of select="concat($www, substring-before(@href,'/en/'), '/', $glang, '/', substring-after(@href,'/en/'))"/>
   </xsl:when>
   <xsl:when test="not (substring(@href,string-length(@href))='/') and not(document(concat(substring-before(@href,'/en/'), '/', $glang, '/', substring-after(@href,'/en/')))/missing)">
    <xsl:value-of select="concat($www, substring-before(@href,'/en/'), '/', $glang, '/', substring-after(@href,'/en/'))"/>
   </xsl:when>
   <xsl:otherwise>
    <xsl:value-of select="concat($www, @href)"/>
   </xsl:otherwise>
  </xsl:choose>
 </xsl:variable>

 <xsl:choose>
   <xsl:when test="../@top='N'">
     <a class="altlink" href="{concat($href,@param)}"><xsl:value-of select="@label"/></a>
     <br/><xsl:if test="not(following-sibling::item)"><br/></xsl:if>
   </xsl:when>
   <xsl:otherwise>
     <a class="menulink" href="{concat($href,@param)}">
     <xsl:if test="starts-with($link, $href)">
       <xsl:attribute name="class">highlight</xsl:attribute>
     </xsl:if>
     <xsl:value-of select="@label"/>
     </a>
     <xsl:if test="following-sibling::item"> | </xsl:if>
   </xsl:otherwise>
 </xsl:choose>
</xsl:template>

</xsl:stylesheet>
