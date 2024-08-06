targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param apiServiceName string = ''
param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param openAiName string = ''
param appServicePlanName string = ''
param cosmosAccountName string = ''
param cosmosDatabaseName string = ''
param cosmosContainers array = []
param keyVaultName string = ''
param logAnalyticsName string = ''
param resourceGroupName string = ''
param storageAccountName string = ''
param webServiceName string = ''
param apimServiceName string = ''

@description('Flag to use Azure API Management to mediate the calls between the Web frontend and the backend API')
param useAPIM bool = false

@description('API Management SKU to use if APIM is enabled')
param apimSku string = 'Consumption'

@description('Id of the user or app to assign application roles')
param principalId string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// The application frontend
module web './app/web.bicep' = {
  name: 'web'
  scope: rg
  params: {
    name: !empty(webServiceName) ? webServiceName : '${abbrs.webStaticSites}web-${resourceToken}'
    location: location
    tags: tags
  }
}

// The application backend
module api './app/api.bicep' = {
  name: 'api'
  scope: rg
  params: {
    name: !empty(apiServiceName) ? apiServiceName : '${abbrs.webSitesFunctions}api-${resourceToken}'
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    appServicePlanId: appServicePlan.outputs.id
    keyVaultName: keyVault.outputs.name
    storageAccountName: storage.outputs.name
    allowedOrigins: [ web.outputs.SERVICE_WEB_URI ]
    appSettings: {
      // cosmos can be retrieved from keyvault
      // AZURE_COSMOS_CONNECTION_STRING_KEY: cosmos.outputs.connectionStringKey
      // AZURE_COSMOS_DATABASE_NAME: cosmos.outputs.databaseName
      // AZURE_COSMOS_ENDPOINT: cosmos.outputs.endpoint
      API_ALLOW_ORIGINS: web.outputs.SERVICE_WEB_URI
    }
  }
}

// Give the API access to KeyVault
module apiKeyVaultAccess './core/security/keyvault-access.bicep' = {
  name: 'api-keyvault-access'
  scope: rg
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: api.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID
  }
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'Y1'
      tier: 'Dynamic'
    }
  }
}

// Backing storage for Azure functions backend API
module storage './core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags
  }
}

// Store secrets in a keyvault
module keyVault './core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
  }
}

module ai 'app/ai.bicep' = {
  name: 'ai'
  scope: rg
  params: {
    name: !empty(openAiName) ? openAiName : '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    location: location
    tags: tags
    keyVaultName: keyVault.outputs.name
  }
}

// assign azure open ai developer role for user
module aiDeveloperRoleUser 'core/security/role.bicep' = {
  name: 'ai-developer-role-user-user'
  scope: rg
  params: {
    principalId: principalId
    roleDefinitionId: '64702f94-c441-49e6-a78b-ef80e0188fee'
    principalType: 'User'
  }
}

// assign azure open ai developer role for api
module aiDeveloperRoleApi 'core/security/role.bicep' = {
  name: 'ai-developer-role-user-api'
  scope: rg
  params: {
    principalId: api.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID
    roleDefinitionId: '64702f94-c441-49e6-a78b-ef80e0188fee'
    principalType: 'ServicePrincipal'
  }
}

// assign azure search service index data contrib role for user
module searchIndexDataContribRoleUser 'core/security/role.bicep' = {
  scope: rg
  name: 'search-index-data-contrib-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
    principalType: 'User'
  }
}

// assign azure search service index data contrib role for user
module searchIndexDataContribRoleApi 'core/security/role.bicep' = {
  scope: rg
  name: 'search-index-data-contrib-role-api'
  params: {
    principalId: api.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID
    roleDefinitionId: '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
    principalType: 'ServicePrincipal'
  }
}

// The application database
module cosmos './app/db.bicep' = {
  name: 'cosmos'
  scope: rg
  params: {
    accountName: !empty(cosmosAccountName) ? cosmosAccountName : '${abbrs.documentDBDatabaseAccounts}${resourceToken}'
    containers: cosmosContainers
    databaseName: cosmosDatabaseName
    location: location
    principalIds: [principalId, api.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID]
    tags: tags
    keyVaultName: keyVault.outputs.name
  }
}

module search './app/search.bicep' = {
  name: 'search'
  scope: rg
  params: {
    name: 'search-${resourceToken}' // todo: add to abbreviations.json
    location: location
    tags: tags
    keyVaultName: keyVault.outputs.name
    principalId: principalId // this should be the user
    indexes: [loadJsonContent('./app/index.json')]
  }
}

// todo: add search service managed identity for user and for api
// principalIds: [principalId, api.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID]


// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}'
  }
}

// Creates Azure API Management (APIM) service to mediate the requests between the frontend and the backend API
module apim './core/gateway/apim.bicep' = if (useAPIM) {
  name: 'apim-deployment'
  scope: rg
  params: {
    name: !empty(apimServiceName) ? apimServiceName : '${abbrs.apiManagementService}${resourceToken}'
    sku: apimSku
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.applicationInsightsName
  }
}

// may need to do something with cors rules?\
var containerName = 'swagger-docs' // todo: parameterize
module swaggerDocsStore './core/storage/storage-account.bicep' = {
  name: 'swagger-docs-store'
  scope: rg
  params: {
    name: '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags
  }
}

// Configures the API in the Azure API Management (APIM) service
// module apimApi './app/apim-api.bicep' = if (useAPIM) {
//   name: 'apim-api-deployment'
//   scope: rg
//   params: {
//     name: useAPIM ? apim.outputs.apimServiceName : ''
//     apiName: 'Eleos'
//     apiDisplayName: 'Eleos Chat API'
//     apiDescription: 'This is a RAG chat API for choosing the best endpoints for your application through NLP queries.'
//     apiPath: 'eleos'
//     webFrontendUrl: web.outputs.SERVICE_WEB_URI
//     apiBackendUrl: api.outputs.SERVICE_API_URI
//     apiAppName: api.outputs.SERVICE_API_NAME
//   }
// }

// Data outputs
output AZURE_COSMOSDB_ENDPOINT string = cosmos.outputs.endpoint
output AZURE_COSMOSDB_CONNECTION_STRING string = cosmos.outputs.connectionStringKey // todo: use managed identity?
output AZURE_COSMOSDB_DATABASE_NAME string = cosmos.outputs.databaseName
output AZURE_COSMOSDB_CONTAINER_NAME string = 'chatmessages' // todo: streamline the bicep templates...

// App outputs
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output API_BASE_URL string = api.outputs.SERVICE_API_URI //useAPIM ? apimApi.outputs.SERVICE_API_URI : api.outputs.SERVICE_API_URI
output REACT_APP_WEB_BASE_URL string = web.outputs.SERVICE_WEB_URI
output USE_APIM bool = useAPIM
//output SERVICE_API_ENDPOINTS array = useAPIM ? [ apimApi.outputs.SERVICE_API_URI, api.outputs.SERVICE_API_URI ]: []

output AZURE_OPENAI_API_ENDPOINT string = ai.outputs.endpoint
output AZURE_OPENAI_API_DEPLOYMENT_NAME string = ai.outputs.chatDeployment
output AZURE_OPENAI_API_EMBEDDINGS_DEPLOYMENT_NAME string = ai.outputs.embeddingDeployment
output AZURE_OPENAI_API_VERSION string = '2024-02-15-preview' // how to get this from bicep template??

output AZURE_AISEARCH_ENDPOINT string = search.outputs.endpoint
output AZURE_AISEARCH_INDEX_NAME string = search.outputs.indexes[0].name
output AZURE_ENV_NAME string = search.outputs.indexes[0].name // todo: rename this in code

output AZURE_BLOB_STORAGE_URL string = storage.outputs.primaryEndpoints.blob
output AZURE_BLOB_STORAGE_CONTAINER string = containerName
