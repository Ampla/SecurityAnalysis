<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet 
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" 
    exclude-result-prefixes="SOAP-ENV"
  >
  
  <xsl:output method="xml" indent="yes" />

  <xsl:variable name="comma" select="','"/>
  <xsl:variable name="crlf" select="'&#xD;&#xA;'"/>
  <xsl:variable name="cr" select="'&#xD;'"/>
  <xsl:variable name="alpha">ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz</xsl:variable>

  <xsl:variable name="defaultDisplayOrder">
    <xsl:variable name="platformVersion" select="/*/Reference[@name='Citect.Ampla.StandardItems']/@version"/>
    <xsl:variable name="majorVersion" select="substring-before($platformVersion, '.')"/>
    <xsl:variable name="minorVersion" select="substring-before(substring-after($platformVersion, '.'), '.')"/>
    <xsl:choose>
      <xsl:when test="($majorVersion > 4)">50000</xsl:when>
      <xsl:when test="($majorVersion = 4) and ($minorVersion >= 2)">50000</xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable> 
  
  <xsl:param name="language"/>
<!--   <xsl:variable name="translations" select="document($language)/Names/Name"/> -->
  <xsl:variable name="translations" select="document($language)/html/body/div[@id]"/>

  <xsl:variable name="pipe">|</xsl:variable>

  <xsl:key name="items-by-reference" match="Item"  use="@reference"/>
  <xsl:key name="items-by-type" match="Item"  use="@type"/>
  <xsl:key name="class-by-id" match="ClassDefinition" use="@id"/>
  <xsl:key name="items-by-id" match="Item" use="@id"/>

  <xsl:template match="/">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="/CitectIIM">
    <xsl:comment>
      <xsl:value-of select="count($translations)"/>
      <xsl:text> Translations</xsl:text>
    </xsl:comment>
    <xsl:element name="Project">
      <xsl:element name="Properties">
        <xsl:element name="ProjectProperty">
          <xsl:attribute name="name">Platform.Version</xsl:attribute>
          <xsl:value-of select="Reference[@name='Citect.Ampla.StandardItems']/@version"/>
        </xsl:element>
        <xsl:element name="ProjectProperty">
          <xsl:attribute name="name">Applications.Version</xsl:attribute>
          <xsl:value-of select="Reference[@name='Citect.Ampla.General.Server']/@version"/>
        </xsl:element>
        <xsl:apply-templates select="@*"/>
      </xsl:element>
      <xsl:apply-templates select="Reference[Type]"/>
      <xsl:apply-templates select="ClassDefinitions/ClassDefinition"/>
      <xsl:apply-templates select="Item"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="/Ampla">
    <xsl:element name="Project">
      <xsl:element name="Properties">
        <xsl:element name="ProjectProperty">
          <xsl:attribute name="name">Platform.Version</xsl:attribute>
          <xsl:value-of select="Reference[@name='Citect.Ampla.StandardItems']/@version"/>
        </xsl:element>
        <xsl:element name="ProjectProperty">
          <xsl:attribute name="name">Applications.Version</xsl:attribute>
          <xsl:value-of select="Reference[@name='Citect.Ampla.General.Server']/@version"/>
        </xsl:element>
        <xsl:apply-templates select="@*"/>
      </xsl:element>
      <xsl:apply-templates select="Reference[Type]"/>
      <xsl:apply-templates select="ClassDefinitions/ClassDefinition"/>
      <xsl:apply-templates select="Item"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="CitectIIM/@*">
    <xsl:element name="ProjectProperty">
      <xsl:attribute name="name">
        <xsl:value-of select="name()"/>
      </xsl:attribute>
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="Ampla/@*">
    <xsl:element name="ProjectProperty">
      <xsl:attribute name="name">
        <xsl:value-of select="name()"/>
      </xsl:attribute>
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="Reference">
    <xsl:if test="count(key('items-by-reference', @name)) > 0">
      <xsl:copy>
        <xsl:apply-templates select="@name"/>
        <xsl:apply-templates select="Type">
          <xsl:with-param name="reference" select="concat(@name, '.')"/>
        </xsl:apply-templates>
      </xsl:copy>
    </xsl:if>
  </xsl:template>

  <xsl:template match="Type">
    <xsl:param name="reference"></xsl:param>
    <xsl:if test="count(key('items-by-type', @name)) > 0">
      <xsl:copy>
        <xsl:attribute name="name">
          <xsl:choose>
            <xsl:when test="contains(@name, $reference)">
              <xsl:value-of select="substring-after(@name, $reference)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="@name"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        <xsl:attribute name="fullName">
          <xsl:value-of select="@name"/>
        </xsl:attribute>        
      </xsl:copy>
    </xsl:if>
  </xsl:template>

  <xsl:template match="ClassDefinition[@id]">
    <xsl:element name="Item">
      <xsl:attribute name="hash">
        <xsl:value-of select="generate-id()"/>
      </xsl:attribute>
      <xsl:apply-templates select="@id"/>
      <xsl:apply-templates select="@name"/>
      <xsl:attribute name="class">true</xsl:attribute>
      <xsl:apply-templates select="@type"/>
      <xsl:attribute name="fullName">
        <xsl:call-template name="getClassFullName"/>
      </xsl:attribute>
      <xsl:call-template name="addTranslation"/>
      <xsl:if test="count(ancestor::ClassDefinition)>1">
        <xsl:element name="Property">
          <xsl:attribute name="name">(inherits)</xsl:attribute>
          <xsl:for-each select="ancestor::ClassDefinition">
            <xsl:if test="position() > 1">
              <xsl:element name="ItemLink">
                <xsl:attribute name="targetID">
                  <xsl:value-of select="@id"/>
                </xsl:attribute>
                <xsl:attribute name="absolutePath">
                  <xsl:call-template name="getClassFullNameById">
                    <xsl:with-param name="classId" select="@id"/>
                  </xsl:call-template>
                </xsl:attribute>
              </xsl:element>
            </xsl:if>
          </xsl:for-each>
        </xsl:element>
      </xsl:if>
      <xsl:for-each select="ancestor-or-self::ClassDefinition/PropertyDefinition">
        <xsl:element name="Property">
          <xsl:apply-templates select="@*"/>
          <xsl:apply-templates/>
        </xsl:element>
      </xsl:for-each>
      <xsl:apply-templates select="ClassDefinition"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="Item[@id]/Property">
    <xsl:copy>
      <xsl:apply-templates select="@id"/>
      <xsl:apply-templates select="@name"/>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Item[@id]/Property[@name='RunState']"/>
  <xsl:template match="Item[@id]/Property[@name='DisplayOrderIndex']"/>
  <xsl:template match="Item[@id]/Property[@name='DisplayOrderGroup']"/>
  <xsl:template match="Item[@id]/Property[@name='PropertyMaskSets']"/>
  <xsl:template match="Item[@id]/Property[@name='DataSource']"/>
  <xsl:template match="Item[@id]/Property[@name='Definition']"/>

  <xsl:template match="Item[@id]">
    <xsl:element name="Item">
      <xsl:call-template name="addItemAttributes"/>
      <xsl:apply-templates select="Property"/>
      <xsl:call-template name="addPropertyDisplayOrder"/>
      <xsl:apply-templates select="Item"/>
    </xsl:element>
  </xsl:template>

  <xsl:template name="addItemAttributes">
    <xsl:attribute name="hash">
      <xsl:value-of select="generate-id()"/>
    </xsl:attribute>
    <xsl:apply-templates select="@id"/>
    <xsl:apply-templates select="@name"/>
    <xsl:apply-templates select="@type"/>
    <xsl:attribute name="fullName">
      <xsl:call-template name="getItemFullName"/>
    </xsl:attribute>
    <xsl:call-template name="addTranslation"/>
    <xsl:apply-templates select="ItemClassAssociation"/>
  </xsl:template>

  <xsl:template name="addDefaultProperty">
    <xsl:param name="propertyName"></xsl:param>
    <xsl:param name="defaultValue"></xsl:param>
    <xsl:choose>
      <xsl:when test="string-length($propertyName)=0"/>
      <xsl:when test="Property[@name=$propertyName]"/>
      <xsl:otherwise>
        <xsl:element name="Property">
          <xsl:attribute name="name">
            <xsl:value-of select="$propertyName"/>
          </xsl:attribute>
          <xsl:value-of select="$defaultValue"/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>
  
  <xsl:template name="addPropertyDisplayOrder">
    <xsl:call-template name="addDefaultProperty">
      <xsl:with-param name="propertyName">DisplayOrder</xsl:with-param>
      <xsl:with-param name="defaultValue" select="$defaultDisplayOrder"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="node()">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!--
     <ItemClassAssociation classDefinitionId="75f769bc-579f-4660-9881-986fc08787e9" />
  -->

  <xsl:template match="ItemClassAssociation[@classDefinitionId]">
    <xsl:element name="Property">
      <xsl:attribute name="name">ClassAssociation</xsl:attribute>
      <xsl:attribute name="class">true</xsl:attribute>
      <xsl:element name="ItemLink">
        <xsl:attribute name="targetID">
          <xsl:value-of select="@classDefinitionId"/>
        </xsl:attribute>
        <xsl:attribute name="absolutePath">
          <xsl:call-template name="getClassFullNameById">
            <xsl:with-param name="classId" select="@classDefinitionId"/>
          </xsl:call-template>
        </xsl:attribute>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  
  <!-- 
        <Item hash="E2HPO" id="553b7781-8a56-4946-9e88-a27fcee91093" name="皮带" type="Citect.Ampla.General.Server.Templating.EquipmentTemplate" fullName="System Configuration.Templates.皮带">
        <Property name="TargetEquipmentClass">75f769bc-579f-4660-9881-986fc08787e9</Property>
  -->
  <xsl:template match="Item[@type='Citect.Ampla.General.Server.Templating.EquipmentTemplate']/Property[@name='TargetEquipmentClass']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:attribute name="class">true</xsl:attribute>
      <xsl:element name="ItemLink">
        <xsl:attribute name="targetID">
          <xsl:value-of select="@classDefinitionId"/>
        </xsl:attribute>
        <xsl:attribute name="absolutePath">
          <xsl:call-template name="getClassFullNameById">
            <xsl:with-param name="classId" select="."/>
          </xsl:call-template>
        </xsl:attribute>
      </xsl:element>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="ExpressionConfig">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:attribute name="text">
        <xsl:call-template name="formatExpression">
          <xsl:with-param name="format" select="@format"/>
          <xsl:with-param name="itemLinks" select="ItemLinkCollection/ItemLink"/>
        </xsl:call-template>      
      </xsl:attribute>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="ExpressionConfig/ItemLinkCollection/ItemLink">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:attribute name="expressionFormat">
        <xsl:call-template name="formatExpression">
          <xsl:with-param name="format" select="@format"/>
          <xsl:with-param name="itemLinks" select="ItemLinkCollection/ItemLink"/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="getProjectFullName">
    <xsl:param name="item-id" select="@id"/>
    <xsl:variable name="item" select="key('items-by-id', $item-id)"/>
    <xsl:for-each select="$item/ancestor-or-self::Item[@id]">
      <xsl:choose>
        <xsl:when test="position()=1">
          <xsl:text>Project.</xsl:text>
        </xsl:when>
        <xsl:when test="position()>1">
          <xsl:text>.</xsl:text>
        </xsl:when>
      </xsl:choose>
      <xsl:variable name="strippedName" select="translate(@name, $alpha, '')"/>
      <xsl:choose>
        <xsl:when test="string-length($strippedName)>0">
          <xsl:text>[</xsl:text>
          <xsl:value-of select="@name"/>
          <xsl:text>]</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@name"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template name="formatExpression">
    <xsl:param name="format"></xsl:param>
    <xsl:param name="itemLinks"></xsl:param>
    <xsl:param name="linkNo">1</xsl:param>
    <xsl:variable name="find" select="concat('#ItemReference', $linkNo - 1, '#')"/>
    <xsl:variable name="replace">
      <xsl:call-template name="getProjectFullName">
        <xsl:with-param name="item-id" select="$itemLinks[position()=$linkNo]/@targetID"/>
      </xsl:call-template>      
    </xsl:variable> 
    <xsl:choose>
      <xsl:when test="$linkNo &lt;= count($itemLinks)">
        <xsl:call-template name="formatExpression">
          <xsl:with-param name="format">
            <xsl:call-template name="findReplace">
              <xsl:with-param name="search" select="$format"/>
              <xsl:with-param name="find" select="$find"/>
              <xsl:with-param name="replace" select="$replace"/>
            </xsl:call-template>
          </xsl:with-param>
          <xsl:with-param name="itemLinks" select="$itemLinks"/>
          <xsl:with-param name="linkNo" select="$linkNo + 1"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$format"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="findReplace">
    <xsl:param name="search"></xsl:param>
    <xsl:param name="find"></xsl:param>
    <xsl:param name="replace"></xsl:param>
    <xsl:choose>
      <xsl:when test="contains($search, $find)">
        <xsl:call-template name="findReplace">
          <xsl:with-param name="search">
            <xsl:value-of select="substring-before($search, $find)"/>
            <xsl:value-of select="$replace"/>
            <xsl:value-of select="substring-after($search, $find)"/>
          </xsl:with-param>
          <xsl:with-param name="find" select="$find"/>
          <xsl:with-param name="replace" select="$replace"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$search"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!--
    <Item name="Bolting State" id="757ca447-2361-4d52-a6c6-eba05a719e26" reference="Citect.Ampla.General.Server" type="Citect.Ampla.General.Server.RecordStates.CycleManager">
      <Property name="Cycles" valueIsXml="True"><Property collection="true" type="Citect.Common.ComparableStringCollection,Citect.Common"><Item>System Configuration.BHPBIC.Common.Cycle Definitions.Continuous Miner.Bolting State</Item></Property></Property>
    </Item>
  -->
  <xsl:template match="Item[@type='Citect.Ampla.General.Server.RecordStates.CycleManager']/Property[@name='Cycles']">
    <xsl:copy>
      <xsl:apply-templates select="@name"/>
      <xsl:for-each select="Property/Item">
        <xsl:element name="ItemLink">
          <xsl:attribute name="absolutePath">
            <xsl:value-of select="."/>
          </xsl:attribute>
        </xsl:element>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Item[@type='Citect.Ampla.Metrics.Server.Resolvers.Resolver']">
    <xsl:element name="Item">
      <xsl:call-template name="addItemAttributes"/>
      <xsl:apply-templates select="Property"/>
      <xsl:call-template name="addPropertyDisplayOrder"/>

      <xsl:call-template name="addDefaultProperty">
        <xsl:with-param name="propertyName">Action</xsl:with-param>
        <xsl:with-param name="defaultValue">Module</xsl:with-param>
      </xsl:call-template>

      <xsl:call-template name="addDefaultProperty">
        <xsl:with-param name="propertyName">ResolverOperation</xsl:with-param>
        <xsl:with-param name="defaultValue">Sum</xsl:with-param>
      </xsl:call-template>

      <xsl:apply-templates select="Item"/>
      
    </xsl:element>
  </xsl:template>

  <xsl:template match="Item[@type='Citect.Ampla.StandardItems.User']">
    <xsl:element name="Item">
      <xsl:call-template name="addItemAttributes"/>
      <xsl:apply-templates select="Property"/>
      <xsl:call-template name="addPropertyDisplayOrder"/>

      <xsl:call-template name="addDefaultProperty">
        <xsl:with-param name="propertyName">Authentication</xsl:with-param>
        <xsl:with-param name="defaultValue">WindowsIntegrated</xsl:with-param>
      </xsl:call-template>

      <xsl:apply-templates select="Item"/>

    </xsl:element>
  </xsl:template>


  <!--                 
    <Item name="Corrida" id="936f0bec-d791-4df6-8472-04f713af989a" reference="Citect.Ampla.Production.Server" type="Citect.Ampla.Production.Server.ProductionFieldDefinition">
      <Property name="CaptureValueForManualRecords">True</Property>
      <Property name="HistoricalFieldExpression" valueIsXml="True"><HistoricalExpressionConfig><ExpressionConfig format="" compileAction="Compile" /><DependencyCollection /></HistoricalExpressionConfig></Property>
      <Property name="RefreshOnManualEntry">True</Property>
    </Item>
-->
  <xsl:template match="Item[@id]/Property[@name='HistoricalFieldExpression']/HistoricalExpressionConfig/ExpressionConfig[@format='']">
    <xsl:variable name="captureManual" select="../../../Property[@name='CaptureValueForManualRecords' and text()='True']"/>
    <xsl:variable name="refreshManual" select="../../../Property[@name='RefreshOnManualEntry' and text()='True']"/>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:if test="$captureManual and $refreshManual">
        <xsl:attribute name="message">No expression specified for Manual records.</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="Property[@name='Home']">
    <xsl:copy>
      <xsl:apply-templates select="@name"/>
      <xsl:variable name="numFavorites" select="count(descendant::*[@type='Citect.Ampla.General.Common.FavoriteDescriptor,Citect.Ampla.General.Common']/Property[@name='LocationType' and text() = 'Home'])"/>
      <xsl:element name="text">
        <xsl:text>{</xsl:text>
        <xsl:value-of select="$numFavorites"/>
        <xsl:text> Favourite(s)}</xsl:text>
      </xsl:element>
      <xsl:apply-templates select="Property[@type='Citect.Ampla.General.Common.FavoriteDescriptor,Citect.Ampla.General.Common']"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Property[@name='Favorites']">
    <xsl:copy>
      <xsl:apply-templates select="@name"/>
      <xsl:variable name="numFavorites" select="count(descendant::*[@type='Citect.Ampla.General.Common.FavoriteDescriptor,Citect.Ampla.General.Common'])"/>
      <xsl:variable name="corruptCount" select="count(descendant::*[@type='Citect.Ampla.General.Common.FavoriteDescriptor,Citect.Ampla.General.Common']/Property[@name='LocationType' and text() != 'Favorite'])"/>
      <xsl:choose>
        <xsl:when test="$numFavorites > 0">
          <xsl:element name="text">
            <xsl:if test="$corruptCount > 0">
              <xsl:attribute name="isCorrupt">true</xsl:attribute>
            </xsl:if>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="$numFavorites"/>
            <xsl:text> Favourite(s)}</xsl:text>
          </xsl:element>
          <xsl:apply-templates select="Property[@type='Citect.Ampla.General.Common.FavoriteDescriptorCollection,Citect.Ampla.General.Common']"/>
        </xsl:when>
        <xsl:otherwise>{0 Favorite(s)}</xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <!-- 
  
<Property name="Favorites" valueIsXml="True">
  <Property dictionary="true" type="Citect.Ampla.General.Common.FavoriteDescriptorCollection,Citect.Ampla.General.Common" keytype="string">
    <Property name="Capacity">16</Property> 
    <Property name="Name">My Favorites</Property> 
    <Item key="2nd Stage Discharge Downtime" type="Citect.Ampla.General.Common.FavoriteDescriptor,Citect.Ampla.General.Common">
      <Property name="DisplayName" type="Citect.Common.Globalization.StringSet,Citect.Common" /> 
      <Property name="Filter">@GroupBy={Production Shift}, Location={"Impala.BMR.Leach Domain.PGM Upgrade.2nd Stage Discharge.Scheibler Filter FI LT 200 Lpm"}, Sample Period={Current "Production Month"}</Property> 
      <Property name="Location">Impala.BMR.Leach Domain.PGM Upgrade.2nd Stage Discharge</Property> 
      <Property name="LocationID">a4fbb4b2-dc47-a319-de58-1464b9daf932</Property> 
      <Property name="LocationType">Favorite</Property> 
      <Property name="Module">Downtime</Property> 
      <Property name="Name">2nd Stage Discharge Downtime</Property> 
      <Property name="NavigationMode">Location</Property> 
      <Property name="PeriodName">Production Shift</Property> 
      <Property name="Recurse">False</Property> 
      <Property name="ViewName">Downtime.Standard View</Property> 
    </Item>
  </Property>
</Property>

  -->

  <xsl:template match="*[@type='Citect.Ampla.General.Common.FavoriteDescriptor,Citect.Ampla.General.Common']">
    <xsl:if test="Property[@name='Location']">
      <xsl:element name="Favorite">
        <xsl:attribute name="name">
          <xsl:value-of select="Property[@name='Name']"/>
        </xsl:attribute>
        <xsl:attribute name="module">
          <xsl:value-of select="Property[@name='Module']"/>
        </xsl:attribute>
        <xsl:if test="Property[@name='Filter']">
          <xsl:attribute name="filter">
            <xsl:value-of select="Property[@name='Filter']"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="Property[@name='Location']">
          <xsl:attribute name="location">
            <xsl:value-of select="Property[@name='Location']"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="Property[@name='Recurse']">
          <xsl:attribute name="recurse">
            <xsl:value-of select="Property[@name='Recurse']"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="Property[@name='ViewName']">
          <xsl:attribute name="view">
            <xsl:value-of select="Property[@name='ViewName']"/>
          </xsl:attribute>
        </xsl:if>
      </xsl:element>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*[@type='Citect.Ampla.General.Common.FavoriteDescriptorCollection,Citect.Ampla.General.Common']">
    <xsl:element name="Favorites">
      <xsl:attribute name="name">
        <xsl:value-of select="Property[@name='Name']"/>
      </xsl:attribute>
      <xsl:apply-templates select="Item[@type='Citect.Ampla.General.Common.FavoriteDescriptorCollection,Citect.Ampla.General.Common']"/>
      <xsl:apply-templates select="Item[@type='Citect.Ampla.General.Common.FavoriteDescriptor,Citect.Ampla.General.Common']"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="Property[SOAP-ENV:Envelope]">
    <xsl:copy>
      <xsl:apply-templates select="@name"/>
      <xsl:attribute name="isSoap">true</xsl:attribute>
      <xsl:text>{SOAP}</xsl:text>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Property[@name='EquipmentTypes']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:call-template name="csvToItemLink">
        <xsl:with-param name="value" select="."/>
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="Property[contains(@name, 'Subscription')]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:choose>
        <xsl:when test="contains(., $pipe)">
          <xsl:element name="text">
            <xsl:apply-templates select="node()"/>
          </xsl:element>
          <xsl:call-template name="extractSubscriptions"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="node()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="extractSubscriptions">
    <xsl:param name="value" select="."/>
    <xsl:choose>
      <xsl:when test="contains($value, $crlf)">
        <xsl:call-template name="createSubscription">
          <xsl:with-param name="line" select="substring-before($value, $crlf)"/>
          <xsl:with-param name="index">0</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="extractSubscriptions">
          <xsl:with-param name="value" select="substring-after($value, $crlf)"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($value, $cr)">
        <xsl:call-template name="createSubscription">
          <xsl:with-param name="line" select="substring-before($value, $cr)"/>
          <xsl:with-param name="index">0</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="extractSubscriptions">
          <xsl:with-param name="value" select="substring-after($value, $cr)"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="createSubscription">
          <xsl:with-param name="line" select="$value"/>
          <xsl:with-param name="index">0</xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="csvToItemLink">
    <xsl:param name="value" select="."/>
    <xsl:choose>
      <xsl:when test="contains($value, $comma)">
        <xsl:call-template name="createItemLink">
          <xsl:with-param name="absolutePath" select="substring-before($value, $comma)"/>
        </xsl:call-template>
        <xsl:call-template name="csvToItemLink">
          <xsl:with-param name="value" select="substring-after($value, $comma)"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="createItemLink">
          <xsl:with-param name="absolutePath" select="$value"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="createItemLink">
    <xsl:param name="absolutePath"/>
    <xsl:element name="ItemLink">
      <xsl:attribute name="absolutePath">
        <xsl:value-of select="$absolutePath"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  <xsl:template name="createSubscription">
    <xsl:param name="line"/>
    <xsl:param name="index">0</xsl:param>
    <xsl:if test="string-length($line) > 0">
      <xsl:choose>
        <xsl:when test="$index=0">
          <!-- type Subscription or AutoSubscription-->
          <xsl:choose>
            <xsl:when test="contains($line, $pipe)">
              <xsl:element name="ItemLink">
                <xsl:attribute name="type">
                  <xsl:value-of select="substring-before($line,$pipe)"/>
                </xsl:attribute>
                <xsl:call-template name="createSubscription">
                  <xsl:with-param name="line" select="substring-after($line, $pipe)"/>
                  <xsl:with-param name="index">1</xsl:with-param>
                </xsl:call-template>
              </xsl:element>
            </xsl:when>
            <xsl:otherwise>
              <xsl:comment>Unexpected Subscription [0]: <xsl:value-of select="$line"/></xsl:comment>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$index=1">
          <!-- Full name-->
          <xsl:choose>
            <xsl:when test="contains($line, $pipe)">
              <xsl:attribute name="absolutePath">
                <xsl:value-of select="substring-before($line,$pipe)"/>
              </xsl:attribute>
              <xsl:call-template name="createSubscription">
                <xsl:with-param name="line" select="substring-after($line, $pipe)"/>
                <xsl:with-param name="index">2</xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:comment>
                Unexpected Subscription [1]: <xsl:value-of select="$line"/>
              </xsl:comment>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$index=2">
          <!-- event -->
          <xsl:choose>
            <xsl:when test="contains($line, $pipe)">
              <xsl:attribute name="event">
                <xsl:value-of select="substring-before($line,$pipe)"/>
              </xsl:attribute>
              <xsl:call-template name="createSubscription">
                <xsl:with-param name="line" select="substring-after($line, $pipe)"/>
                <xsl:with-param name="index">3</xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:comment>
                Unexpected Subscription [2]: <xsl:value-of select="$line"/>
              </xsl:comment>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$index=3">
          <!-- handler -->
          <xsl:choose>
            <xsl:when test="contains($line, $pipe)">
              <xsl:attribute name="handler">
                <xsl:value-of select="substring-before($line,$pipe)"/>
              </xsl:attribute>
              <xsl:call-template name="createSubscription">
                <xsl:with-param name="line" select="substring-after($line, $pipe)"/>
                <xsl:with-param name="index">4</xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="not(contains($line, $pipe))">
              <xsl:attribute name="handler">
                <xsl:value-of select="$line"/>
              </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
              <xsl:comment>
                Unexpected Subscription [3]: <xsl:value-of select="$line"/>
              </xsl:comment>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$index=4">
          <!-- event -->
          <xsl:choose>
            <xsl:when test="not(contains($line, $pipe))">
              <xsl:attribute name="expressionMatch">
                <xsl:value-of select="$line"/>
              </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
              <xsl:comment>
                Unexpected Subscription [4]: <xsl:value-of select="$line"/>
              </xsl:comment>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:comment>
            Unexpected Subscription [<xsl:value-of select="$index"/>]: <xsl:value-of select="$line"/>
          </xsl:comment>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template match="Item[@type='Citect.Ampla.Connectors.OleDbConnector.OleDbAdapter']/Property[SOAP-ENV:Envelope]">
    <xsl:copy>
      <xsl:apply-templates select="@name"/>
      <xsl:attribute name="isSoap">true</xsl:attribute>
      <xsl:variable name="properties" select="descendant::*[namespace-uri()='' and string-length(.) > 0]"/>
      <xsl:choose>
        <xsl:when test="count($properties) > 0">
          <xsl:for-each select="$properties">
            <xsl:element name="soap-property" > 
              <xsl:attribute name="name">
                <xsl:value-of select="name()"/>
              </xsl:attribute>
              <xsl:value-of select="."/>
            </xsl:element>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>{SOAP}</xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <!--
  <Item name="DecisionMatrix" id="2e2b2863-ce00-4f8c-907b-abb5c63a03fa" reference="Citect.Ampla.General.Server" type="Citect.Ampla.General.Server.DecisionMatrix">
    <Item name="Input1" id="ad375879-ba46-4c44-b8da-5c1ad456802b" reference="Citect.Ampla.StandardItems" type="Citect.Ampla.StandardItems.CalculatedVariable">
      <Property name="Sample">0001-01-01 00:00:00.0000000|BadUninitialized|Boolean|False</Property>
      <Property name="SampleTypeCode">Boolean</Property>
    </Item>
    <Item name="Input2" id="270f7ee3-836c-4cab-b998-60df07259aaf" reference="Citect.Ampla.StandardItems" type="Citect.Ampla.StandardItems.CalculatedVariable">
      <Property name="Sample">0001-01-01 00:00:00.0000000|BadUninitialized|Boolean|False</Property>
      <Property name="SampleTypeCode">Boolean</Property>
    </Item>
    <Item name="Input3" id="581f3da6-aacc-4fdf-a6f8-ebe95e0009f7" reference="Citect.Ampla.StandardItems" type="Citect.Ampla.StandardItems.CalculatedVariable">
      <Property name="Sample">0001-01-01 00:00:00.0000000|BadUninitialized|Boolean|False</Property>
      <Property name="SampleTypeCode">Boolean</Property>
    </Item>
    <Item name="Input4" id="c31f2840-9366-4042-854f-92f4119d1a4b" reference="Citect.Ampla.StandardItems" type="Citect.Ampla.StandardItems.CalculatedVariable">
      <Property name="Sample">0001-01-01 00:00:00.0000000|BadUninitialized|Boolean|False</Property>
      <Property name="SampleTypeCode">Boolean</Property>
    </Item>
    <Item name="Rule1" id="44638036-48cb-462e-8538-e27949d626e7" reference="Citect.Ampla.General.Server" type="Citect.Ampla.General.Server.DecisionMatrixRule">
      <Property name="DisplayOrder">1000</Property>
      <Property name="DisplayOrderGroup">6</Property>
      <Property name="Input1">True</Property>
      <Item name="Output1" id="5c79872d-d1c9-443d-a542-1eac1addba1c" reference="Citect.Ampla.StandardItems" type="Citect.Ampla.StandardItems.CalculatedVariable" />
      <Item name="Output2" id="fe21bb51-3ebd-4741-bb31-2280cb21c447" reference="Citect.Ampla.StandardItems" type="Citect.Ampla.StandardItems.CalculatedVariable" />
      <Item name="Output3" id="7f9070a1-8037-401b-b3ad-bbbe46e0dbc6" reference="Citect.Ampla.StandardItems" type="Citect.Ampla.StandardItems.CalculatedVariable" />
    </Item>
    <Item name="Rule2" id="20fb8b44-474b-479d-b87d-89707607b119" reference="Citect.Ampla.General.Server" type="Citect.Ampla.General.Server.DecisionMatrixRule">
      <Property name="DisplayOrder">1000</Property>
      <Property name="DisplayOrderGroup">6</Property>
      <Property name="Input2">True</Property>
      <Item name="Output1" id="a09701e8-9ef8-405c-85eb-eefc533ee945" reference="Citect.Ampla.StandardItems" type="Citect.Ampla.StandardItems.CalculatedVariable" />
      <Item name="Output2" id="bad9b87a-4f71-4233-9ba4-15f64dd56755" reference="Citect.Ampla.StandardItems" type="Citect.Ampla.StandardItems.CalculatedVariable" />
      <Item name="Output3" id="fbedff4f-9407-4a6e-9565-38ff785693be" reference="Citect.Ampla.StandardItems" type="Citect.Ampla.StandardItems.CalculatedVariable" />
    </Item>
    <Item name="Rule3" id="b091f482-fb8d-424e-b4c5-565d994407c6" reference="Citect.Ampla.General.Server" type="Citect.Ampla.General.Server.DecisionMatrixRule">
      <Property name="DisplayOrder">1000</Property>
      <Property name="DisplayOrderGroup">6</Property>
      <Property name="Input3">True</Property>
      <Item name="Output1" id="13b3d1dd-b146-4cab-a83b-626f83452677" reference="Citect.Ampla.StandardItems" type="Citect.Ampla.StandardItems.CalculatedVariable" />
      <Item name="Output2" id="c9b18407-861f-4d00-845c-1990cc8f49eb" reference="Citect.Ampla.StandardItems" type="Citect.Ampla.StandardItems.CalculatedVariable" />
      <Item name="Output3" id="c6e2fb36-71c9-4fa6-a192-59425dc164d8" reference="Citect.Ampla.StandardItems" type="Citect.Ampla.StandardItems.CalculatedVariable" />
    </Item>
    <Item name="Rule4" id="69a10f59-44f9-496f-a9e8-eaadcd06d010" reference="Citect.Ampla.General.Server" type="Citect.Ampla.General.Server.DecisionMatrixRule">
      <Property name="DisplayOrder">1000</Property>
      <Property name="DisplayOrderGroup">6</Property>
      <Property name="Input4">True</Property>
      <Item name="Output1" id="48d65a8d-2d46-4261-bbe9-0ba002793f2a" reference="Citect.Ampla.StandardItems" type="Citect.Ampla.StandardItems.CalculatedVariable" />
      <Item name="Output2" id="b2f8516d-b51b-4782-a98e-7e6359c832cf" reference="Citect.Ampla.StandardItems" type="Citect.Ampla.StandardItems.CalculatedVariable" />
      <Item name="Output3" id="77137bc7-d13f-499a-8ac6-ceab2bae619f" reference="Citect.Ampla.StandardItems" type="Citect.Ampla.StandardItems.CalculatedVariable" />
    </Item>
  </Item>
-->

  <xsl:template match="Item[@type='Citect.Ampla.General.Server.DecisionMatrix']">
    <xsl:element name="Item">
      <xsl:call-template name="addItemAttributes"/>
      <xsl:for-each select="Item[@type='Citect.Ampla.StandardItems.CalculatedVariable']">
        <xsl:element name="Input">
          <xsl:attribute name="hash">
            <xsl:value-of select="generate-id()"/>
          </xsl:attribute>
          <xsl:apply-templates select="@id"/>
          <xsl:apply-templates select="@name"/>
          <xsl:call-template name="addTranslation"/>

          <xsl:attribute name="displayOrder">
            <xsl:choose>
              <xsl:when test="Property[@name='DisplayOrder']">
                <xsl:value-of select="Property[@name='DisplayOrder']"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$defaultDisplayOrder"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:element name="ItemLink">
            <xsl:attribute name="targetID">
              <xsl:value-of select="@id"/>
            </xsl:attribute>
            <xsl:attribute name="absolutePath">
              <xsl:call-template name="getItemFullName"/>
            </xsl:attribute>
          </xsl:element>
        </xsl:element>
      </xsl:for-each>
      <xsl:call-template name="addPropertyDisplayOrder"/>
      <xsl:apply-templates select="Property"/>
      <xsl:apply-templates select="Item"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="Item[@type='Citect.Ampla.General.Server.DecisionMatrixRule']">
    <xsl:element name="Item">
      <xsl:call-template name="addItemAttributes"/>
      <xsl:variable name="properties" select="Property"/>
      <xsl:for-each select="../Item[@type='Citect.Ampla.StandardItems.CalculatedVariable']">
        <xsl:element name="InputRule">
          <xsl:attribute name="name">
            <xsl:value-of select="@name"/>
          </xsl:attribute>
          <xsl:attribute name="displayOrder">
            <xsl:choose>
              <xsl:when test="Property[@name='DisplayOrder']">
                <xsl:value-of select="Property[@name='DisplayOrder']"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$defaultDisplayOrder"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:attribute name="value">
            <xsl:variable name="name" select="@name"/>
            <xsl:choose>
              <xsl:when test="$properties[@name=$name]">
                <xsl:value-of select="$properties[@name=$name]"/>
              </xsl:when>
              <xsl:otherwise>Ignore</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:element name="ItemLink">
            <xsl:attribute name="targetID">
              <xsl:value-of select="@id"/>
            </xsl:attribute>
            <xsl:attribute name="absolutePath">
              <xsl:call-template name="getItemFullName"/>
            </xsl:attribute>
          </xsl:element>
        </xsl:element>
      </xsl:for-each>
      <xsl:call-template name="addPropertyDisplayOrder"/>
      <!-- </xsl:element> -->
      <xsl:apply-templates select="Property"/>
      <xsl:apply-templates select="Item"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="@*">
    <xsl:copy/>    
  </xsl:template>
  
  <xsl:template name="getItemFullName">
    <xsl:for-each select="ancestor-or-self::Item[@id]">
      <xsl:if test="position()>1">
        <xsl:text>.</xsl:text>
      </xsl:if>              
      <xsl:value-of select="@name"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="getClassFullName">
    <xsl:for-each select="ancestor-or-self::ClassDefinition[@id]">
      <xsl:if test="position()>1">
        <xsl:text>.</xsl:text>
      </xsl:if>
      <xsl:value-of select="@name"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="getClassFullNameById">
    <xsl:param name="classId"/>
    <xsl:variable name="class" select="key('class-by-id', $classId)"/>
      <xsl:for-each select="$class/ancestor-or-self::ClassDefinition[@id]">
      <xsl:if test="position()>1">
        <xsl:text>.</xsl:text>
      </xsl:if>
      <xsl:value-of select="@name"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="addTranslation">
    <xsl:param name="name" select="@name"/>
    <xsl:variable name="translation">
      <xsl:call-template name="getTranslation"/>
    </xsl:variable>
    <xsl:if test="string-length($translation)>0">
      <xsl:attribute name="translation">
        <xsl:value-of select="$translation"/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>

  <xsl:template name="getTranslation">
    <xsl:param name="name" select="@name"/>
<!--    <xsl:variable name="lookup" select="$translations[@name=$name]"/> -->
    <xsl:variable name="lookup" select="normalize-space($translations[@id=$name])"/>
    <xsl:choose>
      <xsl:when test="$name=$lookup">
        <!-- return no difference to the translation -->
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$lookup"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
