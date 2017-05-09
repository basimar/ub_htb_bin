<?xml version="1.0" encoding="utf-8"?>
<!--

  marcxml_hierarchy.xsl

  Extracts the information needed to produce a hierarchy structure 
  bottom up out of a set of IDS MARC records, using links in 490 fields.
  Produces a temporary text file

  in:   MARC21 XML slim
  
  out:  unsorted tab separated text file. The fields contain
        1: recno:       recno of current record (001)
        2: uplink:      recno of uplink record (490 $w) or empty, if no uplink
        3: sortform:    if there is an uplink: sort form of uplink numbering (490 $i)
                          else: 'Aktenbildner Person'       (901P_ $a $b $c $d )
                          else: 'Aktenbildner Körperschaft' (902P_ $a $b)
                          else: title of current record (240 $a | 245 $a $n $p)
        4: level:       level of description for ISAD-G style records (351 $c)

  rev. 10.10.2014/andres.vonarx@unibas.ch

-->

<xsl:stylesheet version="1.0"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  >

  <xsl:output method="text" encoding="UTF-8" />
  <xsl:variable name="TAB" select="'&#09;'"/>
  <xsl:variable name="NL" select="'&#x0A;'"/>

  <xsl:template match="/">
    <xsl:value-of select="concat('recno',$TAB,'uplink',$TAB,'sortform',$TAB,'level_of_description',$NL)"/>
    <xsl:for-each select="//marc:record">
        <!-- (1) recno of current record -->
        <xsl:value-of select="marc:controlfield[@tag='001']"/>
        <xsl:value-of select="$TAB"/>
        <!-- (2) recno of uplink record or empty -->
        <xsl:if test="marc:datafield[@tag='490']/marc:subfield[@code='w']">
            <xsl:value-of select="marc:datafield[@tag='490']/marc:subfield[@code='w']"/>
        </xsl:if>
        <xsl:value-of select="$TAB"/>
        <!-- (3) sortform -->
        <xsl:choose>
            <!-- 490 $i: Sortierform Zählung des Teils -->
            <xsl:when test="marc:datafield[@tag='490']/marc:subfield[@code='i']">
                <xsl:value-of select="marc:datafield[@tag='490']/marc:subfield[@code='i']"/>
            </xsl:when>
            <!-- 100$$4cre: Aktenbildner Person -->
            <xsl:when test="marc:datafield[@tag='100']/marc:subfield[@code='a']">
            <xsl:if test="marc:datafield[@tag='100']/marc:subfield[@code='4'] = 'cre'">		
                <xsl:value-of select="marc:datafield[@tag='100']/marc:subfield[@code='a']"/>
                <xsl:if test="marc:datafield[@tag='100']/marc:subfield[@code='b']">
                    <xsl:value-of select="concat(' ', marc:datafield[@tag='100']/marc:subfield[@code='b'], '.')"/>
                </xsl:if>
                <xsl:if test="marc:datafield[@tag='100']/marc:subfield[@code='c']">
                    <xsl:value-of select="concat(', ', marc:datafield[@tag='100']/marc:subfield[@code='c'])"/>
                </xsl:if>
                <xsl:if test="marc:datafield[@tag='100']/marc:subfield[@code='d']">
                    <xsl:value-of select="concat(' (', marc:datafield[@tag='100']/marc:subfield[@code='d'], ')')"/>
                </xsl:if>
            </xsl:if>
            </xsl:when>
            <!-- 110$$4cr: Aktenbildner Körperschaft -->
            <xsl:when test="marc:datafield[@tag='110']/marc:subfield[@code='a']">
			<xsl:if test="marc:datafield[@tag='110']/marc:subfield[@code='4'] = 'cre'">
                <xsl:value-of select="marc:datafield[@tag='110']/marc:subfield[@code='a']"/>
                <xsl:if test="marc:datafield[@tag='110']/marc:subfield[@code='b']">
                    <xsl:value-of select="concat(', ', marc:datafield[@tag='110']/marc:subfield[@code='b'])"/>
                </xsl:if>
            </xsl:if>
            </xsl:when>
            <!-- 111$$4cr: Aktenbildner Kongress -->
            <xsl:when test="marc:datafield[@tag='111']/marc:subfield[@code='a']">
			<xsl:if test="marc:datafield[@tag='111']/marc:subfield[@code='4'] = 'cre'">
                <xsl:value-of select="marc:datafield[@tag='111']/marc:subfield[@code='a']"/>
            </xsl:if>
            </xsl:when>
            <!-- 700$$4cre: Aktenbildner Person -->
            <xsl:when test="marc:datafield[@tag='700']/marc:subfield[@code='a']">
            <xsl:if test="marc:datafield[@tag='700']/marc:subfield[@code='4'] = 'cre'">		
                <xsl:value-of select="marc:datafield[@tag='700']/marc:subfield[@code='a']"/>
                <xsl:if test="marc:datafield[@tag='700']/marc:subfield[@code='b']">
                    <xsl:value-of select="concat(' ', marc:datafield[@tag='700']/marc:subfield[@code='b'], '.')"/>
                </xsl:if>
                <xsl:if test="marc:datafield[@tag='700']/marc:subfield[@code='c']">
                    <xsl:value-of select="concat(', ', marc:datafield[@tag='700']/marc:subfield[@code='c'])"/>
                </xsl:if>
                <xsl:if test="marc:datafield[@tag='700']/marc:subfield[@code='d']">
                    <xsl:value-of select="concat(' (', marc:datafield[@tag='700']/marc:subfield[@code='d'], ')')"/>
                </xsl:if>
            </xsl:if>
            </xsl:when>
            <!-- 710$$4cr: Aktenbildner Körperschaft -->
            <xsl:when test="marc:datafield[@tag='710']/marc:subfield[@code='a']">
			<xsl:if test="marc:datafield[@tag='700']/marc:subfield[@code='4'] = 'cre'">
                <xsl:value-of select="marc:datafield[@tag='710']/marc:subfield[@code='a']"/>
                <xsl:if test="marc:datafield[@tag='710']/marc:subfield[@code='b']">
                    <xsl:value-of select="concat(', ', marc:datafield[@tag='710']/marc:subfield[@code='b'])"/>
                </xsl:if>
            </xsl:if>
            </xsl:when>
            <!-- 711$$4cr: Aktenbildner Kongress -->
            <xsl:when test="marc:datafield[@tag='711']/marc:subfield[@code='a']">
			<xsl:if test="marc:datafield[@tag='711']/marc:subfield[@code='4'] = 'cre'">
                <xsl:value-of select="marc:datafield[@tag='711']/marc:subfield[@code='a']"/>
            </xsl:if>
            </xsl:when>
            <!-- 240|245: Titel -->
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="marc:datafield[@tag='240']">
                        <xsl:value-of select="marc:datafield[@tag='240']/marc:subfield[@code='a']"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="title">
                            <xsl:with-param name="tnode" select="marc:datafield[@tag='245']"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="$TAB"/>
        <!-- (4) level of description -->
        <xsl:value-of select="marc:datafield[@tag='351']/marc:subfield[@code='c']"/>
        <xsl:value-of select="$NL"/>
    </xsl:for-each>
  </xsl:template>

  <!--
    algorithm for selecting subfields from 245 title field:
    * take $a (main title) if first subfield
    * take multiple $n (numeric part) and $p (part), unless preceded by a $d (parallel title)
  -->
  <xsl:template name="title">
    <xsl:param name="tnode"/>
    <xsl:for-each select="$tnode/marc:subfield">
        <xsl:choose>
            <xsl:when test="@code='a' and position()=1">
                <xsl:value-of select="string()"/>
            </xsl:when>
            <xsl:when test="(@code='n' or @code='p') and not(preceding-sibling::*[@code='d'])">
                <xsl:value-of select="concat('. ',string())"/>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
