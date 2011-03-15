<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:func="http://exslt.org/functions" 
                xmlns:exslt="http://exslt.org/common"
                xmlns:date="http://exslt.org/dates-and-times"
                xmlns:str="http://exslt.org/strings"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="exslt func date str dyn">

<!-- Go through doc, parse tests & includes to build
     result doc structure with all chapters/sections/bodies -->

<xsl:variable name="doc-struct" xmlns="">
  <xsl:call-template name="build-doc-struct">
    <xsl:with-param name="doc" select="/"/>
  </xsl:call-template>
</xsl:variable>

<xsl:template name="build-doc-struct" xmlns="">
  <xsl:param name="doc"/>
  <doc-struct>
    <xsl:attribute name="type"><xsl:value-of select="name($doc/*[1])"/></xsl:attribute>
    <file><xsl:value-of select="$link"/></file>
    <xsl:if test="$doc/*[1]/date">
      <date><xsl:value-of select="$doc/*[1]/date"/></date>
    </xsl:if>
    <xsl:if test="$doc/*[1]/version">
      <version><xsl:value-of select="$doc/*[1]/version"/></version>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="$doc/book">
        <xsl:for-each select="$doc/book/part">
          <xsl:variable name="curpart" select="position()"/>
          <bookpart pos="{$curpart}">
            <xsl:for-each select="chapter">
              <xsl:variable name="curchap" select="position()"/>
              <bookchap pos="{$curchap}">
                <xsl:if test="$full='1' or ($curpart=$part and $curchap=$chap)">
                  <xsl:variable name="inc" select="document(include/@href)"/>
                  <file><xsl:value-of select="include/@href"/></file>
                  <xsl:if test="$inc/sections/date">
                    <date><xsl:value-of select="$inc/sections/date"/></date>
                  </xsl:if>
                  <xsl:if test="$inc/sections/version">
                    <version><xsl:value-of select="$inc/sections/version"/></version>
                  </xsl:if>
                 <xsl:for-each select="$inc/sections/section[not(@test) or dyn:evaluate(@test)]">
                  <xsl:call-template name="doc-struct-chapters">
                   <xsl:with-param name="chapter" select="."/>
                  </xsl:call-template>
                 </xsl:for-each>
                </xsl:if>
               </bookchap>
            </xsl:for-each>
           </bookpart>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="$doc//faqindex | $doc/*[1]/chapter[not(@test) or dyn:evaluate(@test)]">
          <xsl:call-template name="doc-struct-chapters">
           <xsl:with-param name="chapter" select="."/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </doc-struct>
</xsl:template>

<xsl:template name="doc-struct-chapters" xmlns="">
<xsl:param name="chapter"/>
   <xsl:choose>
    <xsl:when test="$chapter/include">
      <xsl:variable name="inc" select="document($chapter/include/@href)"/>
      <file><xsl:value-of select="$chapter/include/@href"/></file>
      <xsl:if test="$inc//date">
        <date><xsl:value-of select="$inc//date"/></date>
      </xsl:if>
      <xsl:if test="$inc//version">
        <version><xsl:value-of select="$inc//version"/></version>
      </xsl:if>
      <xsl:for-each select="$inc//chapter[not(@test) or dyn:evaluate(@test)]">
        <xsl:call-template name="doc-struct-chapters">
         <xsl:with-param name="chapter" select="."/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:when>
    <xsl:otherwise>
     <chapter uid="{generate-id($chapter)}" title="{$chapter/title}">
      <xsl:if test="$chapter/@id"><xsl:attribute name="id"><xsl:value-of select="$chapter/@id"/></xsl:attribute></xsl:if>
      <xsl:choose>
        <xsl:when test="body">
          <!-- Handbook section without subsection(s), bodies only -->
          <xsl:for-each select="$chapter/body[not(@test) or dyn:evaluate(@test)]">
            <xsl:call-template name="doc-struct-bodies">
             <xsl:with-param name="body" select="."/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="$chapter/section[not(@test) or dyn:evaluate(@test)] | $chapter/subsection[not(@test) or dyn:evaluate(@test)]">
            <xsl:call-template name="doc-struct-sections">
             <xsl:with-param name="section" select="."/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
     </chapter>
    </xsl:otherwise>
   </xsl:choose> 
</xsl:template>

<xsl:template name="doc-struct-sections" xmlns="">
<xsl:param name="section"/>
    <xsl:choose>
      <xsl:when test="$section/include">
        <xsl:variable name="inc" select="document($section/include/@href)"/>
        <file><xsl:value-of select="$section/include/@href"/></file>
        <xsl:if test="$inc//date">
          <date><xsl:value-of select="$inc//date"/></date>
        </xsl:if>
        <xsl:if test="$inc//version">
          <version><xsl:value-of select="$inc//version"/></version>
        </xsl:if>
        <xsl:for-each select="$inc//section[not(@test) or dyn:evaluate(@test)]">
          <xsl:call-template name="doc-struct-sections">
           <xsl:with-param name="section" select="."/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="$section/body">
       <section uid="{generate-id($section)}" title="{$section/title}">
        <xsl:if test="$section/@id"><xsl:attribute name="id"><xsl:value-of select="$section/@id"/></xsl:attribute></xsl:if>
        <xsl:for-each select="$section/body[not(@test) or dyn:evaluate(@test)]">
          <xsl:call-template name="doc-struct-bodies">
           <xsl:with-param name="body" select="."/>
          </xsl:call-template>
        </xsl:for-each>
       </section>
      </xsl:when>
      <xsl:otherwise>
       <section uid="{generate-id($section)}" title="{$section/title}">
        <!-- bodyless section in old invalid files -->
        <xsl:call-template name="doc-struct-bodies">
         <xsl:with-param name="body" select="$section"/>
        </xsl:call-template>
       </section>
      </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="doc-struct-bodies" xmlns="">
<xsl:param name="body"/>
  <xsl:choose>
    <xsl:when test="$body/include">
      <xsl:variable name="inc" select="document($body/include/@href)"/>
      <file><xsl:value-of select="$body/include/@href"/></file>
      <xsl:if test="$inc//date">
        <date><xsl:value-of select="$inc//date"/></date>
      </xsl:if>
      <xsl:if test="$inc//version">
        <version><xsl:value-of select="$inc//version"/></version>
      </xsl:if>
      <xsl:for-each select="$inc//body[not(@test) or dyn:evaluate(@test)]">
        <xsl:call-template name="doc-struct-bodies">
         <xsl:with-param name="body" select="."/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:when>
    <xsl:otherwise>
     <body uid="{generate-id($body)}">

      <xsl:for-each select="$body/pre[not(@test) or dyn:evaluate(@test)] | $body/figure[not(@test) or dyn:evaluate(@test)]">
       <xsl:element name="{name()}">
        <xsl:attribute name="uid">
         <xsl:value-of select="generate-id(.)"/>
        </xsl:attribute>
       </xsl:element>
      </xsl:for-each>

     </body> 
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>
