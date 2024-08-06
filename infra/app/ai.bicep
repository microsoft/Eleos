param name string
param location string = resourceGroup().location
param tags object = {}

param keyVaultName string

var chatDeploymentName = 'chat'
var chatDeploymentVersion = '2024-05-13'
var embeddingDeploymentName = 'embedding'


module ai '../core/ai/cognitiveservices.bicep' = {
  name: 'cognitiveservices'
  params: {
    name: name
    location: location
    tags: tags
    keyVaultName: keyVaultName
    deployments: [
      {
        name: chatDeploymentName
        model: {
          name: 'gpt-4o'
          format: 'OpenAI'
          version: '2024-05-13'
        }
      }
      {
        name: embeddingDeploymentName
        model: {
          name: 'text-embedding-3-small'
          format: 'OpenAI'
          version: '1'
        }
      }
    ]
  }
}

output chatDeployment string = chatDeploymentName
output chatDeploymentVersion string = chatDeploymentVersion
output embeddingDeployment string = embeddingDeploymentName
output endpoint string = ai.outputs.endpoint
output name string = ai.outputs.name
