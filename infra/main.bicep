targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string = ''

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

// The application frontend
module web './app/web.bicep' = {
  name: 'web'
  scope: rg
  params: {
    suffix: resourceToken
    location: location
    tags: tags
  }
}

module ai './app/ai.bicep' = {
  name: 'ai'
  scope: rg
  params: {
    suffix: resourceToken
    location: location
    tags: tags
  }
}

// The application database
module cosmos './app/db.bicep' = {
  name: 'cosmos'
  scope: rg
  params: {
    suffix: resourceToken
    location: location
    tags: tags
  }
}

module search './app/search.bicep' = {
  name: 'search'
  scope: rg
  params: {
    suffix: resourceToken
    location: location
    tags: tags
  }
}

// Monitor application with Azure Monitor
module monitoring './app/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    suffix: resourceToken
    location: location
    tags: tags
  }
}

module storage './app/storage.bicep' = {
  name: 'swagger-docs-store'
  scope: rg
  params: {
    suffix: resourceToken
    location: location
    tags: tags
  }
}

// The application backend
module api './app/api.bicep' = {
  name: 'api'
  scope: rg
  params: {
    suffix: resourceToken
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    appServicePlanName: 'plan-${resourceToken}'
    allowedOrigins: [ web.outputs.SERVICE_WEB_URI ]
    appSettings: {
      API_ALLOW_ORIGINS: web.outputs.SERVICE_WEB_URI
    }
    openAiOutputs: ai.outputs
    cosmosOutputs: cosmos.outputs
    searchOutputs: search.outputs
    ingestStoreOutputs: storage.outputs
  }
  dependsOn: [ai]
}

module managedIdentity './app/mangedIdentity.bicep' = {
  name: 'managedIdentity'
  scope: rg
  params: {
    cosmosAccountName: cosmos.outputs.name
    userPrincipalId: principalId
    apiIdentity: api.outputs.identity
  }
}

output AZURE_FUNCTION_ENDPOINT string = api.outputs.uri
// output AZURE_FUNCTION_KEY string = '<add your function app key here>'

output AZURE_OPENAI_API_ENDPOINT string = ai.outputs.endpoint
output AZURE_OPENAI_API_DEPLOYMENT_NAME string = ai.outputs.chatDeployment
output AZURE_OPENAI_API_VERSION string = ai.outputs.version
output AZURE_OPENAI_API_EMBEDDINGS_DEPLOYMENT_NAME string = ai.outputs.embeddingDeployment 
// output AZURE_OPENAI_API_KEY string = '<add your open ai key here>'

// output AZURE_COSMOSDB_CONNECTION_STRING string = '<add your cosmos db connection string here>'
output AZURE_COSMOSDB_DATABASE_NAME string = cosmos.outputs.databaseName
output AZURE_COSMOSDB_CONTAINER_NAME string = cosmos.outputs.containerName
output AZURE_COSMOSDB_ENDPOINT string = cosmos.outputs.endpoint
// output AZURE_COSMOSDB_KEY string = '<add your cosmos db key here>'

output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString

output AZURE_AISEARCH_ENDPOINT string = search.outputs.endpoint
// output AZURE_AISEARCH_KEY string = '<add your search key here>'
output AZURE_AISEARCH_INDEX_NAME string = search.outputs.indexName

output AZURE_BLOB_STORAGE_INPUT_CONTAINER string = storage.outputs.inputContainer
output AZURE_BLOB_STORAGE_OUTPUT_CONTAINER string = storage.outputs.outputContainer
output AZURE_BLOB_STORAGE_URL string = storage.outputs.blobEndpoint
// output AZURE_BLOB_STORAGE_KEY string = '<add your blob storage key here>'
// output AZURE_BLOB_CONN_STR string = '<add your blob connection string here>'
