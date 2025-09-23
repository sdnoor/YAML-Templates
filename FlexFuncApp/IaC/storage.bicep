@description('Enter name of Integration for Storage Account')
param integrationNameStorageAccount string

@description('Enter location for storage Account')
param locationStorageAccount string


@description('Enter Environment of the resource') //Always use Dev or Prod. Small d and small p will result in pipeline failure
@allowed([
  'Dev'
  'Prod'
])
param environment string

var storageName = toLower('sto${integrationNameStorageAccount}weu${environment}')

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: storageName
  location: locationStorageAccount

  kind: 'StorageV2'
  sku: {
   name: 'Standard_LRS'
  }
  tags: resourceGroup().tags
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource deploymentContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-01-01' = {
  parent: blobService
  name: 'testContainer'
}


resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2025-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource mediusStatusQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2025-01-01' = {
  parent: queueService
  name: 'testqueue'
}


output storageAccountName string = storageAccount.name
output storageAccountPrimaryEndpoint string = storageAccount.properties.primaryEndpoints.blob
