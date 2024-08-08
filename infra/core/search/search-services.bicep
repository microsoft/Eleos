metadata description = 'Creates an Azure AI Search instance.'
param name string
param location string = resourceGroup().location
param tags object = {}
param keyVaultName string
param searchEndpointStringKey string
param searchKeyStringKey string
param principalId string

param sku object = {
  name: 'standard'
}

param authOptions object = {}
param disableLocalAuth bool = false
param disabledDataExfiltrationOptions array = []
param encryptionWithCmk object = {
  enforcement: 'Unspecified'
}
@allowed([
  'default'
  'highDensity'
])
param hostingMode string = 'default'
param networkRuleSet object = {
  bypass: 'None'
  ipRules: []
}
param partitionCount int = 1
@allowed([
  'enabled'
  'disabled'
])
param publicNetworkAccess string = 'enabled'
param replicaCount int = 1
@allowed([
  'disabled'
  'free'
  'standard'
])
param semanticSearch string = 'disabled'
param indexes array = []

var searchIdentityProvider = (sku.name == 'free') ? null : {
  type: 'SystemAssigned'
}

resource search 'Microsoft.Search/searchServices@2021-04-01-preview' = {
  name: name
  location: location
  tags: tags
  // The free tier does not support managed identity
  identity: searchIdentityProvider
  properties: {
    authOptions: disableLocalAuth ? null : authOptions
    disableLocalAuth: disableLocalAuth
    disabledDataExfiltrationOptions: disabledDataExfiltrationOptions
    encryptionWithCmk: encryptionWithCmk
    hostingMode: hostingMode
    networkRuleSet: networkRuleSet
    partitionCount: partitionCount
    publicNetworkAccess: publicNetworkAccess
    replicaCount: replicaCount
    semanticSearch: semanticSearch
  }
  sku: sku
}

// resource deploymentIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
//   name: '${search.name}-deployment-identity'
//   location: location
// }

// // give user access to the search service to make the index
// module searchServiceContribRoleUser '../security/role.bicep' = {
//   scope: resourceGroup()
//   name: 'search-service-contrib-role-user'
//   params: {
//     principalId: deploymentIdentity.properties.principalId
//     roleDefinitionId: '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
//     principalType: 'ServicePrincipal'
//   }
// }

// resource setupSearchService 'Microsoft.Resources/deploymentScripts@2020-10-01' =  [for index in indexes: {
//   name: 'sendApiRequest-${index.name}'
//   location: location
//   kind: 'AzurePowerShell'
//   identity: {
//     type: 'UserAssigned'
//     userAssignedIdentities: {
//       '${deploymentIdentity.id}': {}
//     }
//   }
//   properties: {
//     azPowerShellVersion: '8.3'
//     timeout: 'PT30M'
//     arguments: '-searchServiceName \\"${search.name}\\" -indexDefinition \\"${index}\\"'// -identity \\"${principalId}\\" -tenant \\"${tenant().tenantId}\\" -subscription \\"${subscription().subscriptionId}\\"'
//     scriptContent: loadTextContent('../../app/SetupIndex.ps1')
//     cleanupPreference: 'OnSuccess'
//     retentionInterval: 'P1D'
//   }
// }]

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// https://learn.microsoft.com/en-us/rest/api/searchmanagement/query-keys/list-by-search-service?view=rest-searchmanagement-2023-11-01&tabs=HTTP#listquerykeysresult
var queryKey = search.listQueryKeys('2021-04-01-preview').value[0].key
var endpoint = 'https://${name}.search.windows.net/'

resource searchEndpoint 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: searchEndpointStringKey
  properties: {
    value: endpoint
  }
}
resource searchKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: searchKeyStringKey
  properties: {
    value: queryKey
  }
}

output id string = search.id
output endpoint string = endpoint
output name string = search.name
output principalId string = !empty(searchIdentityProvider) ? search.identity.principalId : ''

