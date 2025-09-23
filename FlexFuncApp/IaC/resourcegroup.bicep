targetScope = 'subscription'

param location string

@description('Enter environment of the resource')
@allowed([
  'Dev'
  'Prod'
])
param environment string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: toLower('rg-mediusintegrations-weu-${environment}')
  location: location
  tags: {
    department : 'test'
    environment : toLower(environment)
    organization : 'test group'
    project : 'test Integrations'
  }
}
