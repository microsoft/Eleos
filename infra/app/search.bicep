param name string
param location string = resourceGroup().location
param tags object = {}
param searchServiceSkuName string = ''

param keyVaultName string
param searchEndpointStringKey string = 'AZURE-SEARCH-ENDPOINT'
param searchKeyStringKey string = 'AZURE-SEARCH-KEY'
param indexes array = []
param principalId string

module searchService '../core/search/search-services.bicep' = {
  name: 'search-service'
  params: {
    name: name
    location: location
    tags: tags
    keyVaultName: keyVaultName
    searchEndpointStringKey: searchEndpointStringKey
    searchKeyStringKey: searchKeyStringKey
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
    sku: {
      name: !empty(searchServiceSkuName) ? searchServiceSkuName : 'standard'
    }
    semanticSearch: 'free'
    principalId: principalId // this should be the user
    indexes: indexes
  }
}

output indexes array = indexes
output id string = searchService.outputs.id
output name string = searchService.outputs.name
output endpoint string = searchService.outputs.endpoint
