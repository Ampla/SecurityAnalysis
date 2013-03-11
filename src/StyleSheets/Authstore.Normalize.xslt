<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet 
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" 
    exclude-result-prefixes="SOAP-ENV"
  >
  
  <xsl:output method="xml" indent="yes" />

  <xsl:param name="projectSecurity"></xsl:param>
  <xsl:variable name="projectUsers" select="document($projectSecurity)/Security/Users/User"/>
  <xsl:variable name="projectScopes" select="document($projectSecurity)/Security/Scopes/Scope"/>

  <xsl:variable name="scopeDescriptionPrefix">Security scope for </xsl:variable>
  
  <xsl:variable name="crlf" select="'&#xD;&#xA;'"/>

  <xsl:variable name="pipe">|</xsl:variable>

  <xsl:key name="operations-by-guid" match="AzOperation" use="@Guid"/>
  <xsl:key name="tasks-by-guid" match="AzTask" use="@Guid"/>
  <xsl:key name="operationlinks-by-guid" match="OperationLink" use="text()"/>
  <xsl:key name="tasklinks-by-guid" match="TaskLink" use="text()"/>

  <xsl:template match="/">
     <xsl:apply-templates select="/AzAdminManager/AzApplication"/>
  </xsl:template>

  <xsl:template match="/AzAdminManager/AzApplication">
    <xsl:element name="Security">
      <xsl:attribute name="name">
        <xsl:value-of select="@Name"/>
      </xsl:attribute>

      <xsl:element name="Operations">
        <xsl:apply-templates select="AzOperation">
          <xsl:sort select="OperationID" data-type="number"/>
        </xsl:apply-templates>
      </xsl:element>
      
      <xsl:element name="RoleDefinitions">
        <xsl:apply-templates select="AzTask[@RoleDefinition='True']"/>
      </xsl:element>

      <xsl:element name="Scopes">
        <xsl:element name="Scope">
          <xsl:attribute name="name">{Global}</xsl:attribute>
          <xsl:attribute name="scopeId">00000000-0000-0000-0000-000000000000</xsl:attribute>
          <xsl:attribute name="valid">Default scope</xsl:attribute>
          <xsl:apply-templates select="AzRole"/>
        </xsl:element>
        <xsl:apply-templates select="AzScope"/>
        <xsl:call-template name="addProjectScopes"/>
      </xsl:element>

      <xsl:element name="Users">
        <xsl:apply-templates select="$projectUsers">
          <xsl:sort select="Property[@name='DisplayOrder']" data-type="number"/>
          <xsl:sort select="@name"/>
        </xsl:apply-templates>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <xsl:template match="AzOperation">
    <xsl:element name="Operation">
      <xsl:attribute name="operationId">
        <xsl:value-of select="@Guid"/>
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:value-of select="@Name"/>
      </xsl:attribute>
      <xsl:attribute name="description">
        <xsl:value-of select="@Description"/>
      </xsl:attribute>
      <xsl:variable name="operationLinks" select="key('operationlinks-by-guid', @Guid)"/>
      <xsl:if test="$operationLinks">
        <xsl:element name="Links">
          <xsl:for-each select="$operationLinks">
            <xsl:variable name="roleId">
              <xsl:choose>
                <xsl:when test="ancestor::AzTask[@RoleDefinition='True']">
                  <xsl:value-of select="../@Guid"/>
                </xsl:when>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="role" select="key('tasks-by-guid', $roleId)"/>
            <xsl:if test="$role">
              <xsl:call-template name="add-role-link">
                <xsl:with-param name="visited-roles" select="$roleId"/>
                <xsl:with-param name="role" select="$role"/>
              </xsl:call-template>
            </xsl:if>
          </xsl:for-each>
        </xsl:element>
      </xsl:if>
    </xsl:element>
  </xsl:template>

  <xsl:template name="add-role-link">
    <xsl:param name="visited-roles" />
    <xsl:param name="role"/>
    <xsl:element name="RoleLink">
      <xsl:attribute name="name">
        <xsl:value-of select="$role/@Name"/>
      </xsl:attribute>
      <xsl:attribute name="roleId">
        <xsl:value-of select="$role/@Guid"/>
      </xsl:attribute>
      <xsl:variable name="super-roles" select="key('tasklinks-by-guid', $role/@Guid)"/>
      <xsl:for-each select="$super-roles">
        <xsl:variable name="roleId">
          <xsl:choose>
            <xsl:when test="ancestor::AzTask[@RoleDefinition='True']">
              <xsl:value-of select="../@Guid"/>
            </xsl:when>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="role-using-id" select="key('tasks-by-guid', $roleId)"/>
        <xsl:if test="$role-using-id">
          <xsl:call-template name="add-role-link">
            <xsl:with-param name="role" select="$role-using-id"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:for-each>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="AzRole">
    <xsl:variable name="role" select="key('tasks-by-guid', TaskLink)"/>
    <xsl:element name="Role">
      <xsl:attribute name="roleId">
        <xsl:value-of select="$role/@Guid"/>
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:value-of select="$role/@Name"/>
      </xsl:attribute>
      <xsl:attribute name="description">
        <xsl:value-of select="@Description"/>
      </xsl:attribute>
      <xsl:apply-templates select="Member">
        <xsl:sort data-type="text" select="."/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>

  <xsl:template match="Member">
    <xsl:variable name="sid" select="."/>
    <xsl:element name="Member">
      <xsl:attribute name="sid">
        <xsl:value-of select="$sid"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:choose>
          <xsl:when test="contains($sid, 'S-1-5-')">windows</xsl:when>
          <xsl:when test="contains($sid, 'S-1-9-')">ampla</xsl:when>
          <xsl:otherwise>unknown</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:call-template name="addUser">
        <xsl:with-param name="sid" select="$sid"/>
      </xsl:call-template>
    </xsl:element>
  </xsl:template>

  <xsl:template match="AzScope">
    <xsl:variable name="description" select="@Description"/>
    <xsl:variable name="scopeId" select="@Name"/>
    
    <xsl:variable name="scopeName">
      <xsl:choose>
        <xsl:when test="contains($description, $scopeDescriptionPrefix)">
          <xsl:value-of select="substring-after($description, $scopeDescriptionPrefix)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$description"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="Scope">
      <xsl:attribute name="name">
        <xsl:value-of select="$scopeName"/>
      </xsl:attribute>
      <xsl:attribute name="scopeId">
        <xsl:value-of select="$scopeId"/>
      </xsl:attribute>
      <xsl:call-template name="checkScopeInProject">
        <xsl:with-param name="scopeId" select="$scopeId"/>
      </xsl:call-template>
      <xsl:apply-templates select="AzRole"/>
    </xsl:element>
  </xsl:template>

  <xsl:template name="checkScopeInProject">
    <xsl:param name="scopeId"/>
    <xsl:variable name="projectScope" select="$projectScopes[@scopeId = $scopeId]"/>
    <xsl:choose>
      <xsl:when test="count($projectScope) > 0">
        <xsl:attribute name="valid">Scope is Valid</xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="invalid">
          <xsl:text>Warning: Scope does not exist in Ampla Project.</xsl:text>
        </xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="addProjectScopes">
    <xsl:variable name="authstoreScopes" select="/AzAdminManager/AzApplication/AzScope"/>
    <xsl:for-each select="$projectScopes[@id]">
      <xsl:variable name="scopeId" select="@scopeId"/>
      <xsl:choose>
        <xsl:when test="$authstoreScopes[@Name=$scopeId]">
          <!-- Scope found -->
        </xsl:when>
        <xsl:otherwise>
          <xsl:element name="Scope">
            <xsl:attribute name="name">
              <xsl:value-of select="@fullName"/>
            </xsl:attribute>
            <xsl:attribute name="scopeId">
              <xsl:value-of select="$scopeId"/>
            </xsl:attribute>
            <xsl:attribute name="invalid">
              <xsl:text>Warning: Scope does not exist in Authorization Store (AuthStore.xml)</xsl:text>
            </xsl:attribute>
          </xsl:element>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="AzTask[@RoleDefinition='True']">
    <xsl:element name="RoleDefinition">
      <xsl:attribute name="roleId">
        <xsl:value-of select="@Guid"/>
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:value-of select="@Name"/>
      </xsl:attribute>
      <xsl:attribute name="description">
        <xsl:value-of select="@Description"/>
      </xsl:attribute>
      <xsl:apply-templates select="TaskLink"/>
      <xsl:apply-templates select="OperationLink">
        <xsl:sort select="key('operations-by-guid', text())/OperationID" data-type="number"/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>

  <xsl:template match="TaskLink">
    <xsl:variable name="task" select="key('tasks-by-guid', text())"/>
    <xsl:element name="RoleLink">
      <xsl:attribute name="name">
        <xsl:value-of select="$task/@Name"/>
      </xsl:attribute>
      <xsl:attribute name="roleId">
        <xsl:value-of select="$task/@Guid"/>
      </xsl:attribute>
      <xsl:apply-templates select="$task/OperationLink">
        <xsl:sort select="key('operations-by-guid', text())/OperationID" data-type="number"/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>

  <xsl:template match="OperationLink">
    <xsl:variable name="operation" select="key('operations-by-guid', text())"/>
    <xsl:element name="Operation">
      <xsl:attribute name="name">
        <xsl:value-of select="$operation/@Name"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  <xsl:template name="addUser">
    <xsl:param name="sid"></xsl:param>
    <xsl:variable name="userByIdentity" select="$projectUsers[Property[@name='Identity']/Identity/@sid=$sid]"/>
    <xsl:variable name="userBySecurityID" select="$projectUsers[Property[@name='SecurityID']/text()=$sid]"/>
    <xsl:variable name="accountByWellKnownSid">
      <xsl:call-template name="lookupWellKnownSid">
        <xsl:with-param name="sid" select="$sid"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$userByIdentity">
        <xsl:apply-templates select="$userByIdentity" mode="by-identity"/>
      </xsl:when>
      <xsl:when test="$userBySecurityID">
        <xsl:apply-templates select="$userBySecurityID" mode="by-security-id"/>
      </xsl:when>
      <xsl:when test="string-length($accountByWellKnownSid) > 0">
        <xsl:element name="User">
          <xsl:attribute name="name">
            <xsl:value-of select="$sid"/>
          </xsl:attribute>
          <xsl:element name="Identity">
            <xsl:attribute name="name">
              <xsl:value-of select="$accountByWellKnownSid"/>
            </xsl:attribute>
            <xsl:value-of select="$sid"/>
          </xsl:element>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="User">
          <xsl:value-of select="$sid"/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="lookupWellKnownSid">
    <xsl:param name="sid"/>
    <xsl:choose>
      <xsl:when test="$sid = 'S-1-5-32-544'">.\Administrators</xsl:when>
      <xsl:when test="$sid = 'S-1-5-32-545'">.\Users</xsl:when>
      <xsl:when test="$sid = 'S-1-5-32-546'">.\Guests</xsl:when>
      <xsl:when test="$sid = 'S-1-5-32-547'">.\Power Users</xsl:when>
      <xsl:when test="$sid = 'S-1-5-11'">Authenticated Users</xsl:when>
      <xsl:when test="starts-with($sid, 'S-1-5-21-')">
        <xsl:variable name="last3" select="substring($sid,string-length($sid)-3)"/>
        <xsl:variable name="domain" select="substring($sid, 8, string-length($sid)-9-3)"/>
        <xsl:variable name="account">
          <xsl:choose>
            <xsl:when test="$last3 = '500'">Administrator</xsl:when>
            <xsl:when test="$last3 = '512'">Domain Administrators</xsl:when>
            <xsl:when test="$last3 = '513'">Domain Users</xsl:when>
          </xsl:choose>
        </xsl:variable>
        <xsl:if test="string-length($account) > 0">
          <xsl:text>(</xsl:text>
          <xsl:value-of select="$domain"/>
          <xsl:text>)/</xsl:text>
          <xsl:value-of select="$account"/>
        </xsl:if>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="User">
    <xsl:element name="User">
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="Property[@name='Authentication']"/>
      <xsl:apply-templates select="Property[@name='SecurityID']"/>
      <xsl:apply-templates select="Property[@name='Identity']"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="User" mode="by-identity">
    <xsl:element name="User">
      <xsl:apply-templates select="@name"/>
      <xsl:apply-templates select="@id"/>
      <xsl:apply-templates select="@hash"/>
      <xsl:apply-templates select="Property[@name='Identity']/Identity"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="User" mode="by-security-id">
    <xsl:element name="User">
      <xsl:apply-templates select="@name"/>
      <xsl:apply-templates select="@id"/>
      <xsl:apply-templates select="@hash"/>
      <xsl:value-of select="Property[@name='SecurityID']"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="Identity">
    <xsl:copy>
      <xsl:apply-templates select="@name"/>
      <xsl:value-of select="@sid"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Property[@name]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates />
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@*">
    <xsl:copy/>
  </xsl:template>

</xsl:stylesheet>