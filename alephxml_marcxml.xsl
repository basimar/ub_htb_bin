<?xml version="1.0" encoding="utf-8"?>
<!--

  alephxml_marcxml.xsl - convert Aleph X-Service XML files to MARCXML

  usage:   /path/to/saxon -o <output.xml> <input.xml> alephxml_marcxml.xsl

  input:   XML produced by Aleph 18.02 X-Services "present" service
           (e.g. retrieved by aleph_store_set.pl)
  output:  MARCXML: The MARC 21 XML Schema, Version 1.1 (August 4, 2003)

  rev. 24.10.2008/andres.vonarx@unibas.ch

-->

<xsl:stylesheet
    version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.loc.gov/MARC21/slim"
    >

  <xsl:param name="RecordType" select="'Bibliographic'"/>
  <xsl:param name="OrganizationCode" select="'SzZuIDS BS/BE'"/>

  <xsl:output
    method="xml"
    indent="yes"
    encoding="utf-8"
    />

  <xsl:template match="/">
    <collection
        xmlns="http://www.loc.gov/MARC21/slim"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
        <xsl:for-each select="//oai_marc">
          <record>
            <xsl:attribute name="type"><xsl:value-of select="$RecordType"/></xsl:attribute>
            <xsl:apply-templates select="fixfield" mode="leader"/>
            <xsl:apply-templates select="../../doc_number"/>
            <xsl:call-template name="fix-003"/>
            <xsl:apply-templates select="fixfield" mode="numeric"/>
            <xsl:apply-templates select="varfield"/>
            <xsl:apply-templates select="fixfield" mode="local"/>
          </record>
        </xsl:for-each>
    </collection>
  </xsl:template>

  <!--
    leader:
    - take the contents of the LDR field
    - replace illegal content
  -->
  <xsl:template match="fixfield" mode="leader">
    <xsl:if test="@id='LDR'">
        <xsl:element name="leader">
            <xsl:value-of select="translate(.,'-',' ')"/>
        </xsl:element>
    </xsl:if>
  </xsl:template>

  <!--
    document number:
    create a control field '001'
  -->
  <xsl:template match="doc_number">
    <xsl:element name="controlfield">
      <xsl:attribute name="tag"><xsl:value-of select="'001'"/></xsl:attribute>
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>

  <!--
    control field 003
  -->
  <xsl:template name="fix-003">
    <xsl:element name="controlfield">
        <xsl:attribute name="tag"><xsl:value-of select="'003'"/></xsl:attribute>
        <xsl:value-of select="$OrganizationCode"/>
    </xsl:element>
  </xsl:template>

  <!--
    control fields:
    - fixed fields with a numeric tag between 002-009
  -->
  <xsl:template match="fixfield" mode="numeric">
    <xsl:if test="number(@id)&gt;1 and number(@id)&lt;10">
        <xsl:element name="controlfield">
            <xsl:attribute name="tag"><xsl:value-of select="@id"/></xsl:attribute>
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:if>
  </xsl:template>

  <!--
    data fields.
    - ignore 'CAT' fields
  -->
  <xsl:template match="varfield">
    <xsl:if test="@id!='CAT'">
        <xsl:element name="datafield">
            <xsl:attribute name="tag"><xsl:value-of select="@id"/></xsl:attribute>
            <xsl:attribute name="ind1"><xsl:value-of select="@i1"/></xsl:attribute>
            <xsl:attribute name="ind2"><xsl:value-of select="@i2"/></xsl:attribute>
            <xsl:for-each select="subfield">
                <xsl:element name="subfield">
                    <xsl:attribute name="code"><xsl:value-of select="@label"/></xsl:attribute>
                    <xsl:value-of select="."/>
                </xsl:element>
            </xsl:for-each>
        </xsl:element>
    </xsl:if>
  </xsl:template>

  <!--
    local fields:
    - all fixed fields with non-numeric tags or with numeric tags outside the
      range of 001-009 must be converted to data fields. Their content will
      be put into an artificially generated subfield 'a'.
  -->
  <xsl:template match="fixfield" mode="local">
    <xsl:if test="number(@id)=0 or number(@id)&gt;9 or (string(number(@id))='NaN' and @id!='LDR')">
        <xsl:element name="datafield">
            <xsl:attribute name="tag"><xsl:value-of select="@id"/></xsl:attribute>
            <xsl:attribute name="ind1"><xsl:value-of select="' '"/></xsl:attribute>
            <xsl:attribute name="ind2"><xsl:value-of select="' '"/></xsl:attribute>
            <xsl:element name="subfield">
                <xsl:attribute name="code">a</xsl:attribute>
                <xsl:value-of select="."/>
            </xsl:element>
        </xsl:element>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
