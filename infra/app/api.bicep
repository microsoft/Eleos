metadata description = 'Creates an Azure App Service in an existing Azure App Service plan.'

param suffix string
param appServicePlanName string
param location string = resourceGroup().location
param tags object = {}
param applicationInsightsName string
@secure()
param appSettings object = {}
param allowedOrigins array = []
// following are the outputs from each depedency
param openAiOutputs object
param cosmosOutputs object
param searchOutputs object
param ingestStoreOutputs object

var runtimeName = 'python'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
}

// todo: check defaults on resource settings for appservice and storage
resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: 'swa-func-${suffix}'
  location: location
  tags: union(tags, { 'azd-service-name': 'api' })
  kind: 'functionapp,linux'
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: '${runtimeName}|3.11'
      alwaysOn: false
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      minimumElasticInstanceCount: null
      use32BitWorkerProcess: false
      functionAppScaleLimit: null
      healthCheckPath: ''
      appCommandLine: ''
      cors: {
        allowedOrigins: union(['https://portal.azure.com', 'https://ms.portal.azure.com'], allowedOrigins)
      }
    }
    httpsOnly: true
    clientAffinityEnabled: false
  }
  resource basicPublishingCredentialsPoliciesFtp 'basicPublishingCredentialsPolicies' = {
    name: 'ftp'
    properties: {
      allow: false
    }
  }
  resource basicPublishingCredentialsPoliciesScm 'basicPublishingCredentialsPolicies' = {
    name: 'scm'
    properties: {
      allow: false
    }
  }
}

var prefix = 'swafuncstore'
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

resource openAi 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openAiOutputs.name.value
}

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' existing = {
  name: cosmosOutputs.name.value
}

resource search 'Microsoft.Search/searchServices@2021-04-01-preview' existing = {
  name: searchOutputs.name.value
}

resource ingestStore 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: ingestStoreOutputs.name.value
}

// todo: consider trying managed identity for hosting/binding

resource settings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'appsettings'
  parent: appService
  properties: union(appSettings, {
    AZURE_OPENAI_API_ENDPOINT: openAiOutputs.endpoint.value
    AZURE_OPENAI_API_DEPLOYMENT_NAME: openAiOutputs.chatDeployment.value
    AZURE_OPENAI_API_VERSION:  openAiOutputs.version.value
    AZURE_OPENAI_API_EMBEDDINGS_DEPLOYMENT_NAME: openAiOutputs.embeddingDeployment.value
    AZURE_OPENAI_API_KEY: openAi.listKeys().key1
    AZURE_COSMOSDB_CONNECTION_STRING: cosmos.listConnectionStrings().connectionStrings[0].connectionString // todo: is there a way to pull the connection reference inline?
    AZURE_COSMOSDB_DATABASE_NAME: cosmosOutputs.name.value
    AZURE_COSMOSDB_CONTAINER_NAME: cosmosOutputs.containerName.value
    AZURE_COSMOSDB_ENDPOINT: cosmosOutputs.endpoint.value
    AZURE_AISEARCH_ENDPOINT: searchOutputs.endpoint.value
    AZURE_AISEARCH_KEY: search.listAdminKeys().primaryKey
    AZURE_AISEARCH_INDEX_NAME: searchOutputs.indexName.value
    AZURE_BLOB_STORAGE_INPUT_CONTAINER: ingestStoreOutputs.inputContainer.value
    AZURE_BLOB_STORAGE_OUTPUT_CONTAINER: ingestStoreOutputs.outputContainer.value
    AZURE_BLOB_STORAGE_URL: ingestStoreOutputs.blobEndpoint.value
    AZURE_BLOB_STORAGE_KEY: ingestStore.listKeys().keys[0].value
    AZURE_BLOB_CONN_STR:  'DefaultEndpointsProtocol=https;AccountName=${ingestStoreOutputs.name.value};AccountKey=${ingestStore.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}' 
    SCM_DO_BUILD_DURING_DEPLOYMENT: 1
    ENABLE_ORYX_BUILD: 'true'
    PYTHON_ENABLE_GUNICORN_MULTIWORKERS: 'true'
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: runtimeName
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
  })
}

// sites/web/config 'logs'
resource configLogs 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'logs'
  parent: appService
  properties: {
    applicationLogs: { fileSystem: { level: 'Verbose' } }
    detailedErrorMessages: { enabled: true }
    failedRequestsTracing: { enabled: true }
    httpLogs: { fileSystem: { enabled: true, retentionInDays: 1, retentionInMb: 35 } }
  }
  dependsOn: [settings]
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

// storage owner role for functiona app on underlying storage
module userRole './role.bicep' = {
  name: 'openai-userRole'
  params: {
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
  }
}

output identity string = appService.identity.principalId
output name string = appService.name
output uri string = 'https://${appService.properties.defaultHostName}'
