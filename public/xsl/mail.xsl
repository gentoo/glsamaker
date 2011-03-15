<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:exslt="http://exslt.org/common"
                extension-element-prefixes="exslt">

<!-- Process <mail> tags, in a separate .xsl to be included by both
     guide.xsl and GWN-to-text converter
  -->

<!-- Get the list of devs from the roll-call -->
<xsl:variable name="ALL-DEVS" xmlns="">
 <!-- The following embedded <xsl:choose> tags may look a bit verbose,
      but they save using document() twice, once to test, once to load.
      The roll-call is a large file and using document() twice on it is quite slow -->
 <xsl:choose>
  <xsl:when test="$httphost='www'">
   <!-- On www.g.o (default case), roll-call must be userinfo.xml -->
   <xsl:call-template name="load-devs">
    <xsl:with-param name="roll-call" select="document('/proj/en/devrel/roll-call/userinfo.xml')"/>
   </xsl:call-template>
  </xsl:when>
  <xsl:otherwise>
    <!-- Just in case the roll-call is available, wherever we are -->
    <xsl:variable name="local" select="document('/proj/en/devrel/roll-call/userinfo.xml')"/>
    <xsl:choose>
      <xsl:when test="not($local/missing)">
       <xsl:call-template name="load-devs">
        <xsl:with-param name="roll-call" select="$local"/>
       </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <!-- On dev.g.o, try /doc/roll-call.xml as a fallback -->
        <xsl:variable name="fallback" select="document('/doc/roll-call.xml')"/>
        <xsl:choose>
          <xsl:when test="$httphost='dev' and not($fallback/missing)">
           <xsl:call-template name="load-devs">
            <xsl:with-param name="roll-call" select="$fallback"/>
           </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
           <!-- No other choice than to hit www.g.o which could fail, *is slow* AND *disables caching* -->
           <xsl:call-template name="load-devs">
            <xsl:with-param name="roll-call" select="document('http://www.gentoo.org/proj/en/devrel/roll-call/devlist.xml?mode=xml')"/>
           </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:otherwise>
 </xsl:choose>
</xsl:variable>

<xsl:template name="load-devs" xmlns="">
<xsl:param name="roll-call"/>
 <devs>
  <xsl:for-each select="$roll-call/userlist/user">
    <user username="{translate(@username,'QWERTYUIOPLKJHGFDSAZXCVBNM','qwertyuioplkjhgfdsazxcvbnm')}">
     <xsl:if test="translate(status,'TIRED','tired')='retired'">
      <xsl:attribute name="retired"/>
     </xsl:if>
     <xsl:copy-of select="realname"/>
     <xsl:copy-of select="email"/>
    </user>
    <!-- Add another entry for each alias, much easier later on to find right email/name based on an alias -->
    <xsl:for-each select="alias">
      <user username="{.}">
       <xsl:if test="translate(../status,'TIRED','tired')='retired'">
        <xsl:attribute name="retired"/>
       </xsl:if>
       <xsl:copy-of select="../realname"/>
       <xsl:copy-of select="../email"/>
      </user>
    </xsl:for-each>
  </xsl:for-each>
 </devs>
</xsl:template>

<!-- Process mail tag, see if we have a Gentoo dev, add @gentoo.org if required
     and pull name from roll-call if required
     Returns an xml element named mail with optional link attribute
  -->
<xsl:template name="smart-mail" xmlns="">
<xsl:param name="mail"/>
<xsl:if test="string-length($mail/@link)>0 or string-length($mail/text())>0">

 <xsl:variable name="gnick">
  <xsl:choose>
   <xsl:when test="string-length($mail/@link)=0 and not(contains($mail/text(),'@'))">
     <!-- <mail>nick</mail> -->
     <xsl:value-of select="translate($mail/text(),'QWERTYUIOPLKJHGFDSAZXCVBNM','qwertyuioplkjhgfdsazxcvbnm')"/>
   </xsl:when>
   <xsl:when test="string-length($mail/@link)=0 and contains($mail/text(),'@gentoo.org')">
     <!-- <mail>nick@gentoo.org</mail> -->
     <xsl:value-of select="translate(substring-before($mail/text(), '@'),'QWERTYUIOPLKJHGFDSAZXCVBNM','qwertyuioplkjhgfdsazxcvbnm')"/>
   </xsl:when>
   <xsl:when test="string-length($mail/@link)>0 and not(contains($mail/@link,'@'))">
     <!-- <mail link="nick">blah blah</mail> -->
     <xsl:value-of select="translate($mail/@link,'QWERTYUIOPLKJHGFDSAZXCVBNM','qwertyuioplkjhgfdsazxcvbnm')"/>
   </xsl:when>
   <xsl:when test="contains($mail/@link,'@gentoo.org')">
     <!-- <mail link="nick@gentoo.org">blah blah</mail> -->
     <xsl:value-of select="translate(substring-before($mail/@link, '@gentoo.org'),'QWERTYUIOPLKJHGFDSAZXCVBNM','qwertyuioplkjhgfdsazxcvbnm')"/>
   </xsl:when>
  </xsl:choose>
 </xsl:variable>

 <xsl:variable name="gmail">
  <xsl:if test="string-length($gnick)>0">
   <xsl:choose>
    <xsl:when test="exslt:node-set($ALL-DEVS)/devs/user[@username=$gnick and @retired]">
     <xsl:value-of select="exslt:node-set($ALL-DEVS)/devs/user[@username=$gnick]/email[substring-after(text(),'@')!='gentoo.org'][1]"/>
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select="exslt:node-set($ALL-DEVS)/devs/user[@username=$gnick]/email[substring-after(text(),'@')='gentoo.org'][1]"/>
    </xsl:otherwise>
   </xsl:choose>
  </xsl:if>
 </xsl:variable>

 <xsl:variable name="gname">
  <xsl:if test="string-length($gnick)>0">
   <xsl:choose>
    <xsl:when test="exslt:node-set($ALL-DEVS)/devs/user[@username=$gnick]/realname/@fullname">
     <xsl:value-of select="exslt:node-set($ALL-DEVS)/devs/user[@username=$gnick]/realname/@fullname"/>
    </xsl:when>
    <xsl:when test="exslt:node-set($ALL-DEVS)/devs/user[@username=$gnick]/realname[firstname or familyname]">
     <xsl:value-of select="concat(exslt:node-set($ALL-DEVS)/devs/user[@username=$gnick]/realname/firstname,' ',exslt:node-set($ALL-DEVS)/devs/user[@username=$gnick]/realname/familyname)"/>
    </xsl:when>
   </xsl:choose>
  </xsl:if>
 </xsl:variable>

 <xsl:variable name="href">
  <xsl:choose>
  <xsl:when test="string-length($gname)>0 and string-length($gmail)=0 and exslt:node-set($ALL-DEVS)/devs/user[@username=$gnick and @retired]"/>
    <xsl:when test="string-length($gmail)>0">
      <xsl:value-of select="$gmail"/>
    </xsl:when>
    <xsl:when test="string-length($mail/@link)>0 and not(contains($mail/@link,'@'))">
      <xsl:value-of select="concat($mail/@link, '@gentoo.org')"/>
    </xsl:when>
    <xsl:when test="string-length($mail/@link)>0">
      <xsl:value-of select="$mail/@link"/>
    </xsl:when>
    <xsl:when test="string-length($mail/text())>0">
      <xsl:value-of select="$mail/text()"/>
    </xsl:when>
  </xsl:choose>
 </xsl:variable>

 <xsl:variable name="content">
   <xsl:choose>
    <xsl:when test="string-length($mail/@link)>0 and string-length($mail/text())>0">
     <xsl:value-of select="$mail/text()"/>
    </xsl:when>
    <xsl:when test="string-length($gname)>0">
     <xsl:value-of select="$gname"/>
    </xsl:when>
    <xsl:when test="string-length($gmail)>0 and string-length($mail/text())=0">
     <xsl:value-of select="$gmail"/>
    </xsl:when>
    <xsl:when test="string-length($mail/text())=0 and string-length($mail/@link)>0">
     <xsl:value-of select="$mail/@link"/>
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select="$mail/text()"/>
    </xsl:otherwise>
   </xsl:choose>
 </xsl:variable>

 <mail>
  <xsl:if test="string-length($href)>0">
   <xsl:attribute name="link">
    <xsl:value-of select="$href"/>
   </xsl:attribute>
  </xsl:if>
  <xsl:value-of select="$content"/>
 </mail>

</xsl:if>
</xsl:template>

</xsl:stylesheet>
