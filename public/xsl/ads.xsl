<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:template name="ads2">
 <xsl:param name="images"/>
<!-- we already have <table> and <tbody> inherited, hence -->
  <!-- Load sidebar.gentoo.org in iframe -->
    <tr lang="en">
    <td align="center">
          <iframe src="http://sidebar.gentoo.org" scrolling="no" width="125" height="850" frameborder="0" style="border:0px padding:0x" marginwidth="0" marginheight="0">
			<p>Your browser does not support iframes.</p>
          </iframe>
    </td>
    </tr>
  <!-- end of iframe content -->
</xsl:template>


<xsl:template name="ads">
 <xsl:param name="images"/>

  <!-- OSL -->
    <tr lang="en">
    <td align="center" class="topsep">
            <a href="http://osuosl.org/contribute">
      <img src="{concat($images,'images/osuosl.png')}" width="125" height="50" alt="Support OSL" title="Support OSL" border="0"/>
        </a>
    </td>
    </tr>
  <!-- /OSL -->

  <!-- VR -->
    <tr lang="en">
    <td align="center" class="topsep">
            <a href="http://www.vr.org">
      <img src="{concat($images,'images/sponsors/vr-ad.png')}" width="125" height="144" alt="Gentoo Centric Hosting: vr.org" title="Gentoo Centric Hosting: vr.org" border="0"/>
        </a>
    </td>
    </tr>
  <!-- /VR -->

  <!-- Tek -->
    <tr lang="en">
      <td align="center" class="topsep">
      <a href="http://www.tek.net" target="_top">
        <img src="{concat($images,'images/tek-gentoo.gif')}" width="125" height="125" alt="Tek Alchemy" title="Tek Alchemy" border="0"/>
      </a>
      </td>
    </tr>
  <!-- /Tek -->

  <!-- SevenL -->
    <tr lang="en">
    <td align="center" class="topsep">
      <a href="https://www.sevenl.net/?utm_source=gentoo-org&amp;utm_medium=sponsored-banner&amp;utm_campaign=gentoo-dedicated-servers" target="_top">
        <img src="{concat($images,'images/sponsors/sevenl_ad.png')}" width="125" height="125" alt="SevenL.net" title="SevenL.net" border="0"/>
      </a>
    </td>
    </tr>
  <!-- /SevenL -->

  <!-- GNi -->
    <tr lang="en">
    <td align="center" class="topsep">
        <a href="http://www.gni.com" target="_top">
          <img src="{concat($images,'images/gni_logo.png')}" width="125" alt="Global Netoptex Inc." title="Global Netoptex Inc." border="0"/>
      </a>
    </td>
    </tr>
  <!-- /GNi -->
  
  <!-- SD-France -->
    <tr lang="en">
    <td align="center" class="topsep">
        <a href="http://www.euro-web.fr" target="_top">
          <img src="{concat($images,'images/sdfrance-logo-small.png')}" width="125" alt="Euro-Web/SD-France" title="Euro-Web/SD-France" border="0"/>
      </a>
    </td>
    </tr>
  <!-- /SD-France -->

  <!-- bytemark -->
    <tr lang="en">
    <td align="center" class="topsep">
        <a href="http://www.bytemark.co.uk/r/gentoo-home" target="_top">
          <img src="{concat($images,'images/sponsors/bytemark_ad.png')}" width="125" alt="Bytemark" title="Bytemark" border="0"/>
      </a>
    </td>
    </tr>
  <!-- /bytemark -->
  
  <!-- kredit -->
    <tr lang="en">
    <td align="center" class="topsep">
		<a href="http://www.edurium.de/" target="_top">
          <img src="{concat($images,'images/sponsors/edurium-ad.gif')}" width="125" alt="Edurium" title="Edurium" border="0"/>
      </a>
    </td>
    </tr>
  <!-- /kredit -->
</xsl:template>

</xsl:stylesheet>
