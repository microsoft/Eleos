param userPrincipalId string
param apiIdentity string
param cosmosAccountName string

var roleIds = [
  // Storage Blob Data Contributo
'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
// Azure AI Developer
'64702f94-c441-49e6-a78b-ef80e0188fee'
// Search Index Data Contributor
'8ebe5a00-799e-43f5-93ac-243d3dce84a7'
]

module userRoles './role.bicep' = [for roleId in roleIds: {
  name: 'user-${roleId}'
  params: {
    principalId: userPrincipalId
    principalType: 'User'
    roleDefinitionId: roleId
  }
}]

module apiRoles './role.bicep' = [for roleId in roleIds: {
  name: 'api-${roleId}'
  params: {
    principalId: apiIdentity
    principalType: 'ServicePrincipal'
    roleDefinitionId: roleId
  }
}]

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' existing = {
  name: cosmosAccountName
}

resource roleDefinition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2022-08-15' = {
  parent: cosmos
  name: guid(subscription().id, cosmos.id, cosmos.name, 'sql-role')
  properties: {
    assignableScopes: [
      cosmos.id
    ]
    permissions: [
      {
        dataActions: [
          'Microsoft.DocumentDB/databaseAccounts/readMetadata'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*'
        ]
        notDataActions: []
      }
    ]
    roleName: 'Reader Writer'
    type: 'CustomRole'
  }
}

resource userRole 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-05-15' = {
  parent: cosmos
  name: guid(roleDefinition.id, userPrincipalId, cosmos.id)
  properties: {
    principalId: userPrincipalId
    roleDefinitionId: roleDefinition.id
    scope: cosmos.id
  }
}

resource apiRole 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-05-15' = {
  parent: cosmos
  name: guid(roleDefinition.id, apiIdentity, cosmos.id)
  properties: {
    principalId: apiIdentity
    roleDefinitionId: roleDefinition.id
    scope: cosmos.id
  }
}
