<?xml version="1.0" encoding="utf-8"?>
<!--
    extract-recno-from-hierarchy.xsl

    in:  hierarchy.xml (produziert mit htb_hierarchy...)
    out: Textdatei: Liste von Systemnummern

    27.12.2007/andres.vonarx@unibas.ch
-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  >

  <xsl:output method="text" encoding="UTF-8" />
  <xsl:variable name="NL" select="'&#x0A;'"/>

  <xsl:template match="/">
    <xsl:for-each select="//rec">
        <xsl:value-of select="concat(@recno,$NL)"/>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
