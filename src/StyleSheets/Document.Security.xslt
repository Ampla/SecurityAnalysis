<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                >

  <xsl:output method="html"
   doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
   doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
   indent="yes"
  />

  <xsl:key name="scope-by-user-id" match="Scope[Role/Member/User]" use="Role/Member/User/@id"/>
  
  <xsl:template match="/Security">
    <html>
      <head>
        <title>Ampla Project Summary - Security</title>
        <link rel="stylesheet" type="text/css" href="css/security.css" media="screen,projector"/>
      </head>

      <body>
        <div class="header">
        <h1>Ampla Project Summary - Security</h1>
        <hr/>
        </div>
        <span class="menu">
          <a href="#roles">Roles</a>
        </span>
        <span class="menu">
          <a href="#scopes">Scopes</a>
        </span>
        <span class="menu">
          <a href="#users">Users</a>
        </span>
        <hr/>
        <a name="roles"/>
        <h2>Roles</h2>
        <xsl:call-template name="build-role-table"/>
        <br/>
        <hr/>
        <a name="scopes"/>
        <h2>Security Scopes</h2>
        <xsl:call-template name="build-scope-table">
          <xsl:with-param name="scopes" select="/Security/Scopes/Scope[@valid]"/>
        </xsl:call-template>
        <xsl:if test="/Security/Scopes/Scope[@invalid]">
          <br/>
          <hr/>
          <h2>Errors in Security Scopes</h2>
          <xsl:call-template name="build-scope-table">
            <xsl:with-param name="scopes" select="/Security/Scopes/Scope[@invalid]"/>
          </xsl:call-template>
        </xsl:if>
        <br/>
        <hr/>
        <a name="users"/>
        <h2>User Role Assignments</h2>
        <xsl:call-template name="build-user-table"/>
      </body>
    </html>
  </xsl:template>

  <xsl:template name="build-role-table">
    <xsl:variable name="roles" select="/Security/RoleDefinitions/RoleDefinition"/>
    <xsl:variable name="operations" select="/Security/Operations/Operation"/>

    <table>
      <tbody>
        <tr>
          <th>Operation</th>
          <xsl:for-each select="$roles">
            <th>
              <span class="role" title="{@description}">
                <xsl:value-of select="@name"/>
              </span>
            </th>
          </xsl:for-each>
        </tr>
        <xsl:for-each select="$operations">
          <xsl:variable name="operation" select="@name"/>
          <tr>
            <td>
              <span class="operation row-head" title="{@description}">
                <xsl:value-of select="@name"/>
              </span>
            </td>
            <xsl:for-each select="$roles">
              <xsl:variable name="role" select="."/>
              <xsl:variable name="class">
                <xsl:choose>
                  <xsl:when test="$role/descendant::Operation[@name=$operation]">allowed</xsl:when>
                  <xsl:otherwise>denied</xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <xsl:variable name="text">
                <xsl:choose>
                  <xsl:when test="$class='allowed'">Y</xsl:when>
                  <xsl:otherwise>.</xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <td class="center {$class}">
                <span title="{$class}">
                  <xsl:value-of select="$text"/>
                </span>
              </td>
            </xsl:for-each>
          </tr>
        </xsl:for-each>
      </tbody>
    </table>
  </xsl:template>

  <xsl:template name="build-scope-table">
    <xsl:param name="scopes">valid</xsl:param>
    <xsl:variable name="roles" select="/Security/RoleDefinitions/RoleDefinition"/>
    <xsl:variable name="operations" select="/Security/Operations/Operation"/>

    <table>
      <tbody>
        <tr>
          <th>Scope</th>
          
          <xsl:for-each select="$roles">
            <!--<xsl:sort select="count(descendant::Operation)" order="descending"/>
            <xsl:sort select="@name" order="ascending"/>-->
            <th>
              <span class="role" title="{@description}">
                <xsl:value-of select="@name"/>
              </span>
            </th>
          </xsl:for-each>
          
        </tr>
        <xsl:for-each select="$scopes">
          <xsl:variable name="scope" select="."/>
          <tr>
            <td>
              <span class="scope row-head">
                <xsl:value-of select="@name"/>
              </span>
              <xsl:if test="@invalid">
                <br/>
                <span class="warning">
                  <xsl:value-of select="@invalid"/>
                </span>
              </xsl:if>
            </td>
       
            <xsl:for-each select="$roles">
              <xsl:variable name="roleId" select="@roleId"/>
              <xsl:variable name="assignments" select="$scope/Role[@roleId=$roleId]/Member"/>
              <xsl:variable name="class">
                <xsl:choose>
                  <xsl:when test="$assignments">allowed</xsl:when>
                  <xsl:otherwise>denied</xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <xsl:variable name="text">
                <xsl:choose>
                  <xsl:when test="$class='allowed'"></xsl:when>
                  <xsl:otherwise>.</xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <td class="{$class}">
                <!--
                <span>
                  <xsl:value-of select="$text"/>
                </span>
                -->
                <xsl:if test="$assignments">
                  <ul class="assignment">
                    <xsl:apply-templates select="$assignments/User" mode="roleAssignment">
                      <xsl:sort select="concat(@name, 'ZZZ')" data-type="text"/>
                    </xsl:apply-templates>
                  </ul>
                </xsl:if>
              </td>
            </xsl:for-each>
            </tr>
        </xsl:for-each>
      </tbody>
    </table>
  </xsl:template>

  <xsl:template match="User" mode="roleAssignment">
    <xsl:variable name="amplaUser" select="@name"/>
    <xsl:variable name="windowsUser" select="Identity/@name"/>

    <xsl:variable name="title">
      <xsl:text> [</xsl:text>
      <xsl:value-of select="../@type"/>
      <xsl:text>] </xsl:text>
      <xsl:if test="not($amplaUser)">
        <xsl:value-of select="."/>
      </xsl:if>
    </xsl:variable> 
    
    <xsl:variable name="name">
      <xsl:choose>
        <xsl:when test="$amplaUser">
          <xsl:value-of select="@name"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>unknown </xsl:text>
          <xsl:value-of select="../@type"/>
          <xsl:text> user</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="class">
      <xsl:choose>
        <xsl:when test="$amplaUser">user</xsl:when>
        <xsl:otherwise>warning user</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <li title="{$title}">
      <span class="{$class}">
        <xsl:value-of select="$name"/>
      </span>
      <xsl:if test="$windowsUser">
        <br/>
        <span class="identity">
          <xsl:text>(</xsl:text>
          <xsl:value-of select="$windowsUser"/>
          <xsl:text>)</xsl:text>
        </span>
      </xsl:if>
    </li>
  </xsl:template>

  <xsl:template name="build-user-table">
    <xsl:variable name="users" select="/Security/Users/User"/>
    <xsl:variable name="include-invalid" select="/Security/Scopes/Scope[@invalid]"/>
    <table>
      <tbody>
        <tr>
          <th rowspan="2">Users</th>
          <th rowspan="2">Authentication</th>
          <th rowspan="2">Ampla Security</th>
          <th rowspan="2">Windows Identity</th>
          <th colspan="3">Role Assignments</th>
        </tr>
        <tr>
          <th class="allowed">Allowed</th>
          <th class="denied">Denied</th>
          <xsl:if test="$include-invalid">
            <th>Invalid</th>
          </xsl:if>
        </tr>
        <xsl:for-each select="$users">
          <xsl:variable name="user" select="."/>
          <tr>
            <td>
              <span class="user row-head">
                <xsl:value-of select="@name"/>
              </span>
              <xsl:if test="@invalid">
                <br/>
                <span class="warning">
                  <xsl:value-of select="@invalid"/>
                </span>
              </xsl:if>
            </td>
            <td>
              <xsl:value-of select="Property[@name='Authentication']"/>
            </td>
            <td>
              <xsl:value-of select="Property[@name='SecurityID']"/>
            </td>
            <td>
              <xsl:value-of select="Property[@name='Identity']/Identity/@name"/>
            </td>

            <xsl:call-template name="list-scopes">
              <xsl:with-param name="scopes" select="key('scope-by-user-id', $user/@id)[@valid]"/>
              <xsl:with-param name="except-scopes" select="/Security/Scopes/Scope[false()]"/>
              <xsl:with-param name="class">allowed</xsl:with-param>
              <xsl:with-param name="none-class">denied</xsl:with-param>
              <xsl:with-param name="user" select="$user"/>
            </xsl:call-template>

            <xsl:call-template name="list-scopes">
              <xsl:with-param name="scopes" select="/Security/Scopes/Scope[@valid]"/>
              <xsl:with-param name="except-scopes" select="key('scope-by-user-id', $user/@id)[@valid]"/>
              <xsl:with-param name="class">denied</xsl:with-param>
              <xsl:with-param name="user" select="$user"/>
            </xsl:call-template>

            <xsl:if test="$include-invalid">
              <xsl:call-template name="list-scopes">
                <xsl:with-param name="scopes" select="key('scope-by-user-id', $user/@id)[@invalid]"/>
                <xsl:with-param name="except-scopes" select="/Security/Scopes/Scope[false()]"/>
                <xsl:with-param name="class">warning</xsl:with-param>
                <xsl:with-param name="user" select="$user"/>
              </xsl:call-template>
            </xsl:if>
          </tr>
        </xsl:for-each>
      </tbody>
    </table>
  </xsl:template>

  <xsl:template name="list-scopes">
    <xsl:param name="scopes"/>
    <xsl:param name="except-scopes"/>
    <xsl:param name="class"/>
    <xsl:param name="none-class"/>
    <xsl:param name="user"/>
    <xsl:choose>
      <xsl:when test="(count($scopes) > 0) and (count($scopes) >  count($except-scopes))">
        <td class="{$class}">
          <ul>
            <xsl:for-each select="$scopes">
              <xsl:sort select="@invalid"/>
              <xsl:sort select="@valid"/>
              <xsl:sort select="@name"/>
              <xsl:variable name="scope" select="."/>
              <xsl:choose>
                <xsl:when test="$except-scopes[@scopeId = $scope/@scopeId]">
                  <!-- don't include scope -->
                </xsl:when>
                <xsl:otherwise>
                  <li>
                    <xsl:choose>
                      <xsl:when test="$scope/@invalid">
                        <span class="scope warning" title="{$scope/@invalid}">
                          <xsl:value-of select="@name"/>
                        </span>
                      </xsl:when>
                      <xsl:otherwise>
                        <span class="scope">
                          <xsl:value-of select="@name"/>
                        </span>
                      </xsl:otherwise>
                    </xsl:choose>
                    <xsl:variable name="roles" select="Role[Member/User[@id=$user/@id]]"/>
                    <xsl:choose>
                      <xsl:when test="count($roles) > 0">
                        <ul>
                          <xsl:for-each select="$roles">
                            <li>
                              <span class="{$class}">
                                <xsl:value-of select="@name"/>
                              </span>
                            </li>
                          </xsl:for-each>
                        </ul>
                      </xsl:when>
                    </xsl:choose>
                  </li>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </ul>
        </td>
      </xsl:when>
      <xsl:otherwise>
        <td class="{$none-class}">
        </td>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="(count($scopes) > 0) and (count($scopes) >  count($except-scopes))">
    </xsl:if>    
  </xsl:template>
  
</xsl:stylesheet>
