<?xml version="1.0" encoding="utf-8"?>
<!--

  tigra_tree_menu_full.xsl - builds the tree_items.js file used in the Tigra javascript tree menu.

  "full" heisst: alle Informationen stammen aus der Hiearachie XML-Datei, es wird keine MARC XML benoetigt.

  usage:  saxon <hierarchy.xml> tigra_tree_menu_full.xsl [ROOTNODE=0] [INFOXML=<info.xml>] [VARNAME=TREE_ITEMS]

  input files:
    <hierarchy.xml>   structured hierarchy xml of records (mandatory)
    <info.xml>        XML file with additional info (optional)

  parameters:
    ROOTNODE:   If set to '0', no additional root node will be generated.
                If set to '1' (=default), an artificial root node will be
                generated, taking @text and @href from the <rootnode> element
                in the INFOXML file.

    INFOXML:    File name of XML file with some additional info.
                Mandatory, if ROOTNODE is true (=default).
                The following elements from INFOXML will be used:
                  //rootnode/@text     Text of additional root node
                  //rootnode/@href     Link of additional root node

    VARNAME:    Name of the JavaScript variable in the output where tree
                items will get stored (default: TREE_ITEMS)

  see also: http://www.softcomplex.com/products/tigra_menu_tree/

  history:
    rev. 25.11.2014  andres.vonarx@unibas.ch
-->

<xsl:stylesheet version="1.0"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="marc"
  >

  <xsl:param name="INFOXML">-</xsl:param>
  <xsl:param name="ROOTNODE">1</xsl:param>
  <xsl:param name="VARNAME">TREE_ITEMS</xsl:param>

  <xsl:output method="text" encoding="UTF-8" />

  <xsl:variable name="NL" select="'&#x0A;'"/>
  <xsl:variable name="TAB" select="'&#09;'"/>
  <!-- fix some characters bound to cause trouble in JavaScript -->
  <xsl:variable name="BAD_QUOTES">&apos;&quot;</xsl:variable>
  <xsl:variable name="SAFE_QUOTES">&#x2019;&#x201D;</xsl:variable>

  <xsl:template match="/tree">
    <xsl:value-of select="concat('// data generated: ',@generated,$NL)"/>
    <xsl:value-of select="concat('var ',$VARNAME,' = [',$NL)"/>
    <!-- start root node -->
    <xsl:if test="$ROOTNODE!=0">
        <xsl:if test="$INFOXML='-'">
            <xsl:message terminate="yes">Missing XSLT Parameter: INFOXML</xsl:message>
        </xsl:if>
        <xsl:text>  ['</xsl:text>
        <xsl:value-of select="document($INFOXML)//rootnode/@text"/>
        <xsl:text>','</xsl:text>
        <xsl:value-of select="document($INFOXML)//rootnode/@href"/>
        <xsl:text>',</xsl:text>
        <xsl:value-of select="$NL"/>
    </xsl:if>
    <!-- descend into nodes -->
    <xsl:call-template name="printlevel">
        <xsl:with-param name="node" select="."/>
    </xsl:call-template>
    <!-- end root node -->
    <xsl:if test="$ROOTNODE!=0">
        <xsl:value-of select="concat('  ]',$NL)"/>
    </xsl:if>
    <xsl:value-of select="concat('];',$NL)"/>
  </xsl:template>

  <!-- recursively print the hierarchical levels -->
  <xsl:template name="printlevel">
    <xsl:param name="node"/>
      <xsl:for-each select ="rec">
        <!-- opening bracket -->
        <xsl:call-template name="indent">
            <xsl:with-param name="level" select="@level"/>
        </xsl:call-template>
        <xsl:value-of select="'['"/>
        <!-- print current record (closes brackets, if without children) -->
        <xsl:call-template name="printrec">
            <xsl:with-param name="recno" select="@recno"/>
            <xsl:with-param name="level" select="@level"/>
        </xsl:call-template>
        <xsl:value-of select="$NL"/>
        <!-- recurse into deeper levels -->
        <xsl:call-template name="printlevel">
            <xsl:with-param name="node" select="."/>
        </xsl:call-template>
        <!-- close bracket, if node had children -->
        <xsl:if test="rec">
            <xsl:call-template name="indent">
                <xsl:with-param name="level" select="@level"/>
            </xsl:call-template>
            <xsl:value-of select="']'"/>
            <xsl:if test="position()!=last()">
                <xsl:value-of select="','"/>
            </xsl:if>
            <xsl:value-of select="$NL"/>
        </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!-- print appropriate indentation for each level -->
  <xsl:template name="indent">
    <xsl:param name="level"/>
    <xsl:if test=" number($level) > 0 ">
        <xsl:value-of select="$TAB"/>
        <xsl:call-template name="indent">
            <xsl:with-param name="level" select="number($level)-1"/>
        </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- print a Tigra tree menu item: quoted text and link -->
  <xsl:template name="printrec">
    <xsl:param name="level"/>
    <xsl:param name="recno"/>
    <xsl:text>'</xsl:text>
    <xsl:if test="$level!=1">
        <xsl:if test="data/numbering">
            <xsl:value-of select="translate(data/numbering,$BAD_QUOTES,$SAFE_QUOTES)"/>
            <xsl:value-of select="' : '"/>
        </xsl:if>
    </xsl:if>
    <xsl:value-of select="translate(data/title,$BAD_QUOTES,$SAFE_QUOTES)"/>
    <xsl:text>','javascript:bib(\'</xsl:text>
    <xsl:value-of select="$recno"/>
    <xsl:text>\');'</xsl:text>
    <!-- close bracket, if node has no children -->
    <xsl:choose>
        <xsl:when test="rec">
            <xsl:value-of select="','"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="'],'"/>
        </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
