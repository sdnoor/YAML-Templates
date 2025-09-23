@description('Enter name of Integration')
param integrationName string

@description('Enter location for your resources')
@allowed([
  'Sweden Central'
])
param location string

@description('Enter Environment of the resource')
@allowed([
  'Dev'
  'Prod'
])
param environment string

param deploymentContainerUrl string

//KeyVault
param keyVaultName string
param keyvaultResourceGroupName string

//Service Plan Sku
param spSkuName string
param spSkuTier string

param integrationNameStorageAccount string
param integrationNameServiceBus string

//Function App Configurations
param applicationName string
param aiConnectString string // Application Insights connection string
param vnetSubnetId string
@secure()
param sftpUsernameSecretName string
@secure()
param sftpPasswordSecretName string

var appPlanName = toLower('sp-${integrationName}-weu-${environment}')
var funcName = toLower('func-${integrationName}-swc-${environment}')
var storageName = toLower('sto${integrationNameStorageAccount}weu${environment}')
var serviceBusNameSpaceName = toLower('sbns-${integrationNameServiceBus}-weu-${environment}')

resource keyVault 'Microsoft.KeyVault/vaults@2024-12-01-preview' existing = {
  scope: resourceGroup(keyvaultResourceGroupName)
  name: keyVaultName
}

resource StorageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' existing = {
  name: storageName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: appPlanName
  location: location
  tags: resourceGroup().tags
  properties: {
    reserved: true
  }
  sku: {
    name: spSkuName
    tier: spSkuTier
  }
}

resource azureFunction 'Microsoft.Web/sites@2024-11-01' = {
  name: funcName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  tags: resourceGroup().tags
  properties: {
    serverFarmId: appServicePlan.id
    reserved: true
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'FunctionConfig__EnvironmentLevel'
          value: environment
        }
        {
          name: 'FunctionConfig__ApplicationName'
          value: applicationName
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${StorageAccount.name};AccountKey=${StorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'AzureWebJobsStorage__accountName'
          value: StorageAccount.name
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: aiConnectString
        }
        {
          name: 'APPLICATIONINSIGHTS_ENABLE_AGENT'
          value: 'true'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'
        }
        
        {
          name: 'FunctionConfig__SFTP__Username'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${sftpUsernameSecretName})'
        }
        {
          name: 'FunctionConfig__SFTP__Password'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${sftpPasswordSecretName})'
        }
        {
          name: 'ServiceBusConnection__fullyQualifiedNamespace'
          value: '${serviceBusNameSpaceName}.servicebus.windows.net'
        }
      ]
      netFrameworkVersion: 'v8.0'
    }
    functionAppConfig: {
      runtime: {
        name: 'dotnet-isolated'
        version: '8.0'
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 50
        instanceMemoryMB: 2048
      }
      deployment: {
        storage: {
          type: 'blobContainer'
          value: deploymentContainerUrl
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
    }
  }
}


// Attach VNet (Regional VNet Integration)
resource vnetIntegration 'Microsoft.Web/sites/networkConfig@2024-11-01' = {
  parent: azureFunction
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: vnetSubnetId
    swiftSupported: true
  }
}

// Grant the function app access to Key Vault secrets
module keyVaultAccessPolicy './keyVaultAccessPolicy.bicep' = {
  name: 'keyVaultAccessPolicy'
  scope: resourceGroup(keyvaultResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    principalId: azureFunction.identity.principalId
  }
}

output functionAppId string = azureFunction.id
output functionPrincipalId string = azureFunction.identity.principalId
