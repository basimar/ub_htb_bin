<?xml version="1.0" encoding="utf-8"?>
<!--

  tigra_tree_menu.xsl - builds the tree_items.js file used in the Tigra javascript tree menu.

  usage:  /path/to/saxon <hierarchy.xml> tigra_tree_menu.xsl MARCXML=<marc.xml> [INFOXML=<info.xml>]
             [ROOTNODE=0] [VARNAME=TREE_ITEMS]

  input files:
    <hierarchy.xml>   structured hierarchy xml of records (mandatory)
    <marc.xml>        MARC 21 Slim XML file (mandatory)
    <info.xml>        XML file with additional info (optional)

  parameters:
    MARCXML:    File name of MARC 21 Slim XML (mandatory)

    INFOXML:    File name of XML file with some additional info.
                Mandatory, if ROOTNODE is true (=default).
                The following elements from INFOXML will be used:
                  //rootnode/@text     Text of additional root node
                  //rootnode/@href     Link of additional root node

    ROOTNODE:   If set to '0', no additional root node will be generated.
                If set to '1' (=default), an artificial root node will be
                generated, taking @text and @href from the <rootnode> element
                in the INFOXML file.

    VARNAME:    Name of the JavaScript variable in the output where tree
                items will get stored (default: TREE_ITEMS)

    HTITLE:     Title comes from hierarchy file, not from MARC file.
                If set to '1', the title of an element will be retrieved
                from the input file ("rec/data/title"), if present,
                otherwise from the MARCXML.
                If set to '0' (default), the title will allways be retrieved
                from the MARCXML (datafiled 245, subfield a).

    JS_CMD      Name of the JavaScript: command which will be used for the URL
                of each item. Default is 'bib'. The command will receive the
                Aleph record number as its first parameter.

  see also: http://www.softcomplex.com/products/tigra_menu_tree/

  history:
    21.04.2006  andres.vonarx@unibas.ch
    12.01.2007  fix bad quotes in titles from inputfile
    18.01.2010  do not assume there is a 490 $v in child elements; use 240/245 for title
    10.09.2010  new parameter JS_CMD

-->

<xsl:stylesheet version="1.0"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="marc"
  >

  <xsl:param name="MARCXML">-</xsl:param>
  <xsl:param name="INFOXML">-</xsl:param>
  <xsl:param name="ROOTNODE">1</xsl:param>
  <xsl:param name="VARNAME">TREE_ITEMS</xsl:param>
  <xsl:param name="HTITLE">0</xsl:param>
  <xsl:param name="JS_CMD">bib</xsl:param>

  <xsl:output method="text" encoding="UTF-8" />

  <xsl:variable name="NL" select="'&#x0A;'"/>
  <xsl:variable name="TAB" select="'&#09;'"/>
  <!-- fix some characters bound to cause trouble in JavaScript -->
  <xsl:variable name="BAD_QUOTES">&apos;&quot;</xsl:variable>
  <xsl:variable name="SAFE_QUOTES">&#x2019;&#x201D;</xsl:variable>

  <xsl:template match="/tree">
    <xsl:if test="$MARCXML='-'">
        <xsl:message terminate="yes">Missing XSLT Parameter: MARCXML</xsl:message>
    </xsl:if>
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
        <!-- for children: prepend '490 $v :' to title, if there is one -->
        <xsl:call-template name="subfield">
            <xsl:with-param name="recno" select="$recno"/>
            <xsl:with-param name="field" select="'490'"/>
            <xsl:with-param name="subfield" select="'v'"/>
        </xsl:call-template>
        <xsl:if test="document($MARCXML)//marc:controlfield[@tag='001'
                and string()=$recno]/../marc:datafield[@tag='490']/marc:subfield[@code='v']">
            <xsl:value-of select="' : '"/>
        </xsl:if>
    </xsl:if>
    <xsl:choose>
        <xsl:when test="$HTITLE=1">
            <xsl:choose>
                <xsl:when test="data/title">
                    <xsl:value-of select="translate(data/title,$BAD_QUOTES,$SAFE_QUOTES)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="title">
                        <xsl:with-param name="recno" select="$recno"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="title">
                <xsl:with-param name="recno" select="$recno"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>','javascript:</xsl:text><xsl:value-of select="$JS_CMD"/><xsl:text>(\'</xsl:text>
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


  <!-- print a MARC subfield. Replace quotes with safe Unicode characters -->
  <xsl:template name="subfield">
    <xsl:param name="recno"/>
    <xsl:param name="field"/>
    <xsl:param name="subfield"/>
    <xsl:value-of select="translate(document($MARCXML)//marc:controlfield[@tag='001'
      and string()=$recno]/../marc:datafield[@tag=$field]/marc:subfield[@code=$subfield],$BAD_QUOTES,$SAFE_QUOTES)"/>
  </xsl:template>

  <!-- print Title (240 or 245) -->
  <xsl:template name="title">
    <xsl:param name="recno"/>
    <xsl:choose>
        <xsl:when test="document($MARCXML)//marc:controlfield[@tag='001'
              and string()=$recno]/../marc:datafield[@tag='240']/marc:subfield[@code='a']">
            <xsl:call-template name="subfield">
                <xsl:with-param name="recno" select="$recno"/>
                <xsl:with-param name="field" select="'240'"/>
                <xsl:with-param name="subfield" select="'a'"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="subfield">
                <xsl:with-param name="recno" select="$recno"/>
                <xsl:with-param name="field" select="'245'"/>
                <xsl:with-param name="subfield" select="'a'"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
