<?xml version="1.0" encoding="utf-8"?>
<!--
    extract-top-info.xsl
    
   
    in:  MARC 21 XML
    
    out: TSV Textdatei mit den Feldern
         - Systemnummer,
         - Sortierfeld (Aktenbildner),
         - XML-Data (Aktenbildner),

    parameter:
        p = Aktenbildenr Privatperson (901P)
        k = Aktenbildner Körperschaft (902P)

    history:
        13.11.2008/ava: rev.
        14.03.2011/osc: Umstellung auf mehrere Aktenbildner
        29.09.2014/ava: parameter p/k
        04.01.2016/bmt: Anpassunge HAN-Formatwechsel (Abschaffung 901/902-Felder)
-->
<xsl:stylesheet version="1.0"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  >

    <xsl:output method="text" encoding="UTF-8" />
    <xsl:variable name="TAB" select="'&#09;'"/>
    <xsl:variable name="NL" select="'&#x0A;'"/>
    <xsl:param name="typ" />

    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="$typ='k'">
                <!-- Aktenbildner Körperschaft -->
                <xsl:for-each select="//marc:datafield[@tag='110']/marc:subfield[@code='a']">
                    <xsl:if test="../marc:subfield[@code='4'] = 'cre'">
                    	<!-- sysno -->
						<xsl:value-of select="../../marc:controlfield[@tag='001']"/>
						<xsl:value-of select="$TAB"/>
                    
						<!-- Sortierfeld -->
						<xsl:value-of select="."/>
						<xsl:if test="../marc:subfield[@code='b']">
							<xsl:value-of select="concat(', ', ../marc:subfield[@code='b'])"/>
						</xsl:if>
						<xsl:value-of select="$TAB"/>
                    
						<!-- Anzeigeform -->
						<xsl:text>&lt;title&gt;</xsl:text>
						<xsl:value-of select="."/>
						<xsl:if test="../marc:subfield[@code='b']">
							<xsl:value-of select="concat(', ', ../marc:subfield[@code='b'])"/>
						</xsl:if>
						<xsl:text>&lt;/title&gt;</xsl:text>
						<xsl:value-of select="$NL"/>
					</xsl:if>
                </xsl:for-each>
                <xsl:for-each select="//marc:datafield[@tag='111']/marc:subfield[@code='a']">
                    <xsl:if test="../marc:subfield[@code='4'] = 'cre'">
                    	<!-- sysno -->
						<xsl:value-of select="../../marc:controlfield[@tag='001']"/>
						<xsl:value-of select="$TAB"/>
                    
						<!-- Sortierfeld -->
						<xsl:value-of select="."/>
						<xsl:if test="../marc:subfield[@code='b']">
							<xsl:value-of select="concat(', ', ../marc:subfield[@code='b'])"/>
						</xsl:if>
						<xsl:value-of select="$TAB"/>
                    
						<!-- Anzeigeform -->
						<xsl:text>&lt;title&gt;</xsl:text>
						<xsl:value-of select="."/>
						<xsl:if test="../marc:subfield[@code='b']">
							<xsl:value-of select="concat(', ', ../marc:subfield[@code='b'])"/>
						</xsl:if>
						<xsl:text>&lt;/title&gt;</xsl:text>
						<xsl:value-of select="$NL"/>
					</xsl:if>
                </xsl:for-each>
                <xsl:for-each select="//marc:datafield[@tag='710']/marc:subfield[@code='a']">
                    <xsl:if test="../marc:subfield[@code='4'] = 'cre'">
                    	<!-- sysno -->
						<xsl:value-of select="../../marc:controlfield[@tag='001']"/>
						<xsl:value-of select="$TAB"/>
                    
						<!-- Sortierfeld -->
						<xsl:value-of select="."/>
						<xsl:if test="../marc:subfield[@code='b']">
							<xsl:value-of select="concat(', ', ../marc:subfield[@code='b'])"/>
						</xsl:if>
						<xsl:value-of select="$TAB"/>
                    
						<!-- Anzeigeform -->
						<xsl:text>&lt;title&gt;</xsl:text>
						<xsl:value-of select="."/>
						<xsl:if test="../marc:subfield[@code='b']">
							<xsl:value-of select="concat(', ', ../marc:subfield[@code='b'])"/>
						</xsl:if>
						<xsl:text>&lt;/title&gt;</xsl:text>
						<xsl:value-of select="$NL"/>
					</xsl:if>
                </xsl:for-each>
                <xsl:for-each select="//marc:datafield[@tag='711']/marc:subfield[@code='a']">
                    <xsl:if test="../marc:subfield[@code='4'] = 'cre'">
                    	<!-- sysno -->
						<xsl:value-of select="../../marc:controlfield[@tag='001']"/>
						<xsl:value-of select="$TAB"/>
                    
						<!-- Sortierfeld -->
						<xsl:value-of select="."/>
						<xsl:if test="../marc:subfield[@code='b']">
							<xsl:value-of select="concat(', ', ../marc:subfield[@code='b'])"/>
						</xsl:if>
						<xsl:value-of select="$TAB"/>
                    
						<!-- Anzeigeform -->
						<xsl:text>&lt;title&gt;</xsl:text>
						<xsl:value-of select="."/>
						<xsl:if test="../marc:subfield[@code='b']">
							<xsl:value-of select="concat(', ', ../marc:subfield[@code='b'])"/>
						</xsl:if>
						<xsl:text>&lt;/title&gt;</xsl:text>
						<xsl:value-of select="$NL"/>
					</xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="$typ='p'">
		
                <!-- Aktenbildner Person -->
                <xsl:for-each select="//marc:datafield[@tag='100']/marc:subfield[@code='a']">
					<xsl:if test="../marc:subfield[@code='4'] = 'cre'">
						<!-- sysno -->
						<xsl:value-of select="../../marc:controlfield[@tag='001']"/>
						<xsl:value-of select="$TAB"/>

						<!-- Sortierfeld -->
						<xsl:value-of select="."/>
						<xsl:if test="../marc:subfield[@code='b']">
							<xsl:value-of select="concat(' ', ../marc:subfield[@code='b'], '.')"/>
						</xsl:if>
						<xsl:if test="../marc:subfield[@code='c']">
							<xsl:value-of select="concat(', ', ../marc:subfield[@code='c'])"/>
						</xsl:if>
						<xsl:if test="../marc:subfield[@code='d']">
							<xsl:value-of select="concat(' (', ../marc:subfield[@code='d'], ')')"/>
						</xsl:if>
						<xsl:value-of select="$TAB"/>

						<!-- Anzeigeform -->
						<xsl:text>&lt;title&gt;</xsl:text>
						<xsl:value-of select="."/>
						<xsl:if test="../marc:subfield[@code='b']">
							<xsl:value-of select="concat(' ', ../marc:subfield[@code='b'], '.')"/>
						</xsl:if>
						<xsl:for-each select="../marc:subfield[@code='c']">
							<xsl:value-of select="concat(', ', .)"/>
						</xsl:for-each>
						<xsl:if test="../marc:subfield[@code='d']">
							<xsl:value-of select="concat(' (', ../marc:subfield[@code='d'], ')')"/>
						</xsl:if>
						<xsl:text>&lt;/title&gt;</xsl:text>
						<xsl:value-of select="$NL"/>
					</xsl:if>	
                </xsl:for-each>
                <xsl:for-each select="//marc:datafield[@tag='700']/marc:subfield[@code='a']">
					<xsl:if test="../marc:subfield[@code='4'] = 'cre'">
						<!-- sysno -->
						<xsl:value-of select="../../marc:controlfield[@tag='001']"/>
						<xsl:value-of select="$TAB"/>

						<!-- Sortierfeld -->
						<xsl:value-of select="."/>
						<xsl:if test="../marc:subfield[@code='b']">
							<xsl:value-of select="concat(' ', ../marc:subfield[@code='b'], '.')"/>
						</xsl:if>
						<xsl:if test="../marc:subfield[@code='c']">
							<xsl:value-of select="concat(', ', ../marc:subfield[@code='c'])"/>
						</xsl:if>
						<xsl:if test="../marc:subfield[@code='d']">
							<xsl:value-of select="concat(' (', ../marc:subfield[@code='d'], ')')"/>
						</xsl:if>
						<xsl:value-of select="$TAB"/>

						<!-- Anzeigeform -->
						<xsl:text>&lt;title&gt;</xsl:text>
						<xsl:value-of select="."/>
						<xsl:if test="../marc:subfield[@code='b']">
							<xsl:value-of select="concat(' ', ../marc:subfield[@code='b'], '.')"/>
						</xsl:if>
						<xsl:for-each select="../marc:subfield[@code='c']">
							<xsl:value-of select="concat(', ', .)"/>
						</xsl:for-each>
						<xsl:if test="../marc:subfield[@code='d']">
							<xsl:value-of select="concat(' (', ../marc:subfield[@code='d'], ')')"/>
						</xsl:if>
						<xsl:text>&lt;/title&gt;</xsl:text>
						<xsl:value-of select="$NL"/>
					</xsl:if>	
                </xsl:for-each>
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:message terminate="yes">FEHLER: Unbekannter Parameter 'typ'. Erlaubt sind 'p' und 'k'.</xsl:message>
            </xsl:otherwise>
            
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
