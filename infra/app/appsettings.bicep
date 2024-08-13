metadata description = 'Sets the appSettings for an existing Azure App Service. If updating be sure to union with existing settings prior to sending updated settings as input.'

param appName string
// secured for any secrets inside
@secure()
param updatedAppsettings object

resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appName
}

resource apiAppSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'appsettings'
  parent: appService
  properties: updatedAppsettings
}
