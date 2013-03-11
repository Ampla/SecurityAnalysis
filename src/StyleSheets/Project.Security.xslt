<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                >
  <xsl:output method="xml" indent="yes"/>

  <xsl:variable name="pipe">|</xsl:variable>

  <xsl:key name="items-by-id" match="Item" use="@id"/>

  <xsl:template match="/">
    <xsl:element name="Security">
      <xsl:element name="Users">
        <xsl:for-each select="//Item[@type='Citect.Ampla.StandardItems.User']">
          <xsl:sort data-type="text" select="../@fullName"/>
          <xsl:sort data-type="number" select="Property[@name='DisplayOrder']"/>
          <xsl:sort data-type="text" select="@name"/>
          <xsl:element name="User">
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="Property[@name='DisplayOrder']"/>
            <xsl:apply-templates select="Property[@name='Authentication']"/>
            <xsl:apply-templates select="Property[@name='Identity']"/>
            <xsl:apply-templates select="Property[@name='SecurityID']"/>
          </xsl:element>
        </xsl:for-each>
      </xsl:element>
      <xsl:element name="Scopes">
        <xsl:element name="Scope">
          <xsl:attribute name="scopeId">00000000-0000-0000-0000-000000000000</xsl:attribute>
          <xsl:attribute name="name">{Global}</xsl:attribute>
          <xsl:attribute name="fullName">{Global}</xsl:attribute>
        </xsl:element>
        <xsl:for-each select="//Item[Property[@name='InheritPermissions']/text()='False']">
          <xsl:sort data-type="text" select="../@fullName"/>
          <xsl:sort data-type="number" select="Property[@name='DisplayOrder']"/>
          <xsl:sort data-type="text" select="@name"/>
          <xsl:element name="Scope">
            <xsl:attribute name="scopeId">
              <xsl:value-of select="@id"/>
            </xsl:attribute>
            <xsl:apply-templates select="@*"/>
          </xsl:element>
        </xsl:for-each>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  
  <!-- 
          <Property name="Identity">APAC\fisha1|S-1-5-21-1379841381-2888069222-2292527902-168445|&lt;NULL&gt;</Property>
  -->
  <xsl:template match="Property[@name='Identity']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>

      <xsl:variable name="value" select="."/>
      <xsl:variable name="account">
        <xsl:value-of select="substring-before($value, $pipe)"/>
      </xsl:variable>
      <xsl:variable name="sid">
        <xsl:value-of select="substring-before(substring-after($value, $pipe), $pipe)"/>
      </xsl:variable>
      <xsl:element name="Identity">
        <xsl:if test="string-length($account)>0">
          <xsl:attribute name="name">
            <xsl:value-of select="$account"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="string-length($sid)>0">
          <xsl:attribute name="sid">
            <xsl:value-of select="$sid"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:value-of select="$value"/>
      </xsl:element>
    </xsl:copy>
  </xsl:template>
  
  
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
