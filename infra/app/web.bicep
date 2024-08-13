metadata description = 'Creates an Azure Static Web Apps instance.'

param suffix string
param location string = resourceGroup().location
param tags object = {}

resource web 'Microsoft.Web/staticSites@2022-03-01' = {
  name: 'swa-${suffix}'
  location: location
  tags: union(tags, { 'azd-service-name': 'web' })
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    provider: 'Custom'
  }
}

output SERVICE_WEB_NAME string = web.name
output SERVICE_WEB_URI string = 'https://${web.properties.defaultHostname}'
