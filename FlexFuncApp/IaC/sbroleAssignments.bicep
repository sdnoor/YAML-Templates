targetScope = 'resourceGroup'

@description('Enter Environment of the resource')
@allowed([
  'Dev'
  'Prod'
])
param environment string

param serviceFunctionPrincipalId string

param serviceBusName string
param serviceBusResourceGroup string
param serviceBusSubscriptionId string = subscription().subscriptionId

// Azure Service Bus Data Sender Role
resource serviceBusDataSenderRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
}

// Azure Service Bus Data Receiver Role
resource serviceBusDataReceiverRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
}

// module servicebus 'servicebus.bicep' = {
//   scope: resourceGroup(serviceBusSubscriptionId, serviceBusResourceGroup)
//   params: {
//     environment: environment
//     serviceBusSubscriptionId: serviceBusSubscriptionId
//     serviceBusResourceGroup: serviceBusResourceGroup
//   }
// }

// bring the target RG into scope
// resource serviceBusRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
//   scope: subscription(serviceBusSubscriptionId)
//   name: serviceBusResourceGroup
// }

// Reference to the Service Bus
resource ServiceBusNamespace 'Microsoft.ServiceBus/namespaces@2024-01-01' existing = {
  // scope: serviceBusRg
  name: serviceBusName
}

var serviceBusResourceId = '/subscriptions/${serviceBusSubscriptionId}/resourceGroups/${serviceBusResourceGroup}/providers/Microsoft.ServiceBus/namespaces/${serviceBusName}'

// Assign Azure Service Bus Data Sender Role to the Service Function
resource serviceFunctionServiceBusSenderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: ServiceBusNamespace
  name: guid(serviceBusResourceId, serviceFunctionPrincipalId, serviceBusDataSenderRole.id)
  properties: {   
    roleDefinitionId: serviceBusDataSenderRole.id
    principalId: serviceFunctionPrincipalId
    principalType: 'ServicePrincipal'
  }
}



// Assign Azure Service Bus Data Receiver Role to the Service Function
resource serviceFunctionServiceBusReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: ServiceBusNamespace
  name: guid(serviceBusResourceId, serviceFunctionPrincipalId, serviceBusDataReceiverRole.id)
  properties: {   
    roleDefinitionId: serviceBusDataReceiverRole.id
    principalId: serviceFunctionPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output resolvedSbNsId string = ServiceBusNamespace.id
