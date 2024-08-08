param accountName string
param location string = resourceGroup().location
param tags object = {}

param containers array = []
param databaseName string = ''
param principalIds array = []
param keyVaultName string

// Because databaseName is optional in main.bicep, we make sure the database name is set here.
var defaultDatabaseName = 'chathistorydb'
var actualDatabaseName = !empty(databaseName) ? databaseName : defaultDatabaseName

// Because containers is optional in main.bicep, we make sure that a default container is set here
var defaultContainerName = 'chatmessages'
var actualContainers = !empty(containers) ? containers : [defaultContainerName]

module cosmos '../core/database/cosmos/sql/cosmos-sql-db.bicep' = {
  name: 'cosmos-sql'
  params: {
    accountName: accountName
    databaseName: actualDatabaseName
    containers: [for containerName in actualContainers: {
        name: containerName
        id: containerName
        partitionKey: '/partitionkey'// should this be something else?
      }
    ]
    location: location
    principalIds: principalIds
    keyVaultName: keyVaultName
    tags: tags
  }
}

metadata description = 'Creates an Azure Cosmos DB for NoSQL account with a database.'

output connectionStringKey string = cosmos.outputs.connectionStringKey
output databaseName string = cosmos.outputs.databaseName
output endpoint string = cosmos.outputs.endpoint
output containers array = actualContainers
