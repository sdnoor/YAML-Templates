
@description('Enter name of your function App')
param integrationName string


@description('Enter location for your resources')
@allowed([
  'westeurope'
])
param Location string

@description('Enter Enviroment of the resource')
@allowed([
  'Dev'
  'Prod'
])
param Enviroment string

@description('Enter Short Name of Storage Account resource')
param StorageAccShortName string

@description('Storage Account type')
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])
param StorageAccountType string = 'Standard_LRS'

var funcName = toLower('func-${integrationName}-weu-${Enviroment}')

var appPlanName = toLower('sp-integrationName-weu-${Enviroment}')
var aiName = toLower('ai-integrationName-weu-${Enviroment}')
var storageAccName = toLower('sto${StorageAccShortName}weu${Enviroment}')
var IntegrationResourceGroup = Enviroment == 'Dev' ? 'rg-test-weu-dev' : 'rg-test-weu-prod'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccName
  location: Location
  kind: 'StorageV2'
  sku: {
    name: StorageAccountType
  }
}

resource appInsightsComponents 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: aiName
  location: Location
  kind: 'web'
  tags: {
    enviroment: Enviroment
  }
  properties: {
    Application_Type: 'web'
    SamplingPercentage: 100
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appPlanName
  location: Location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 1
  }
  kind: 'windows'
}

resource azureFunctionQueue 'Microsoft.Web/sites@2024-04-01' = {
  name: funcName
  location: Location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        // {
        //   name: 'AzureWebJobsDashboard'
        //   value: 'DefaultEndpointsProtocol=https;AccountName=${PosJsonReceiptStorageAcc};AccountKey=${listKeys(storageAccRef.id, '2019-06-01').keys[0].value}'
        // }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(funcName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsComponents.properties.ConnectionString
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
          name: 'FunctionConfig:StorageAccountConnectionString'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE '
          value: '1'
        }
      ]
      netFrameworkVersion: 'v8.0'
    }
  }
}

