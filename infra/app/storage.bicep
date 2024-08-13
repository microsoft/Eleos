param suffix string
param tags object = {}
param location string = resourceGroup().location

var prefix = 'ingeststore'
var prefixLen = length(prefix)
var suffixLen = length(suffix)
var cleanStorageName = prefixLen + suffixLen > 24 ? substring('${prefix}${suffix}', 0, 24) : '${prefix}${suffix}'

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: cleanStorageName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: { name: 'Standard_LRS' }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    allowCrossTenantReplication: true
    allowSharedKeyAccess: true
    defaultToOAuthAuthentication: false
    dnsEndpointType: 'Standard'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    publicNetworkAccess: 'Enabled'
    supportsHttpsTrafficOnly: true
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storage
  name: 'default'
}

resource inputContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobServices
  name: 'swagger-docs'
}

resource outputContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobServices
  name: 'processed'
}

output id string = storage.id
output name string = storage.name
output inputContainer string = inputContainer.name
output outputContainer string = outputContainer.name
output blobEndpoint string = storage.properties.primaryEndpoints.blob
