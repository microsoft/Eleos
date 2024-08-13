param suffix string
param location string = resourceGroup().location
param tags object = {}

var name = 'openai-${suffix}'
var chatDeploymentName = 'chat'
var chatDeploymentVersion = '2024-05-13'
var embeddingDeploymentName = 'embedding'

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'OpenAI'
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
    disableLocalAuth: false
  }
  sku: {
    name: 'S0'
  }
}

resource chat 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: account
  name: chatDeploymentName
  properties: {
    model: {
      name: 'gpt-4o'
      format: 'OpenAI'
      version: '2024-05-13'
    }
    raiPolicyName: null
  }
  sku: {
    name: 'Standard'
    capacity: 20
  }
}

resource embedding 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: account
  name: embeddingDeploymentName
  properties: {
    model: {
      name: 'text-embedding-3-small'
      format: 'OpenAI'
      version: '1'
    }
    raiPolicyName: null
  }
  sku: {
    name: 'Standard'
    capacity: 20
  }
  dependsOn: [chat] // you can only perform one deployment at a time
}

output chatDeployment string = chatDeploymentName
output chatDeploymentVersion string = chatDeploymentVersion
output embeddingDeployment string = embeddingDeploymentName
output endpoint string = account.properties.endpoint
output name string = account.name
output version string = '2024-02-15-preview' // todo: how can we get this from bicep?
