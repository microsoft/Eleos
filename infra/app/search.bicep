param suffix string
param location string = resourceGroup().location
param tags object = {}

resource search 'Microsoft.Search/searchServices@2021-04-01-preview' = {
  name: 'search-${suffix}'
  location: location
  tags: tags
  identity: {type:'SystemAssigned'}
  sku: {
    name: 'standard'
  }
  properties: {
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
    disableLocalAuth: false
    disabledDataExfiltrationOptions: []
    encryptionWithCmk: {
      enforcement: 'Unspecified'
    }
    hostingMode: 'default'
    networkRuleSet: {
      bypass: 'None'
      ipRules: []
    }
    partitionCount: 1
    publicNetworkAccess: 'enabled'
    replicaCount: 1
    semanticSearch: 'free'
  }
}

var indexName = 'swagger-docs-index'

// todo: upsert index definition here

output id string = search.id
output endpoint string = 'https://${search.name}.search.windows.net/'
output name string = search.name
output indexName string = indexName
output principalId string = search.identity.principalId
