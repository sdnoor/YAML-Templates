param integrationNameServiceBus string

@description('Enter Enviroment of the resource')
@allowed([
  'Dev'
  'Prod'
])
param environment string

// @description('Location of the resources')
// param location string = 'westeurope'

param serviceBusResourceGroup string
param serviceBusSubscriptionId string

var serviceBusNameSpaceName = toLower('sbns-${integrationNameServiceBus}-weu-${environment}')

resource ServiceBusNamespace 'Microsoft.ServiceBus/namespaces@2024-01-01' existing = {  
  scope: resourceGroup(serviceBusSubscriptionId, serviceBusResourceGroup)
  name: serviceBusNameSpaceName
  // location: location
  // sku: {
  //   name: 'Standard'
  //   capacity: 1
  //   tier: 'Standard'
  // }
}

// resource inRiverPolicy 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2024-01-01' = {
//   name: 'InriverListenPolicy'
//   properties: {
//     rights: [
//       'Listen'
//     ]
//   }
//   parent: ServiceBusNamespace

// }

// resource matasSLPolicy 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2024-01-01' = {
//   name: 'MatasSendListenPolicy'
//   properties: {
//     rights: [
//       'Listen'
//       'Send'
//     ]
//   }
//   parent: ServiceBusNamespace

// }

output serviceBusName string = ServiceBusNamespace.name
output serviceBusId string = ServiceBusNamespace.id
