targetScope = 'resourceGroup'

param datalakeName string
// param datalakeStorageResourceGroupName string
param datalakeStorageSubscriptionId string
param serviceFunctionPrincipalId string




// Storage Blob Data Read/Write
// resource storageBlobDataReadWriteRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
//   name: '9184b0e6-3d4c-4c0f-9bde-0bf4210fbab6'
//   scope: subscription(datalakeStorageSubscriptionId)
// }

// Reference to the Storage Account
resource storageAccountDataLake 'Microsoft.Storage/storageAccounts@2025-01-01' existing = {
  name: datalakeName
  // scope: resourceGroup(datalakeStorageResourceGroupName)
}

var customRoleGuid = '9184b0e6-3d4c-4c0f-9bde-0bf4210fbab6'
var roleDefinitionId = '/subscriptions/${datalakeStorageSubscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${customRoleGuid}'


// Assign Storage Blob Data Read/Write Role to the Service Function
resource serviceFunctionRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccountDataLake
  name: guid(storageAccountDataLake.id, serviceFunctionPrincipalId, roleDefinitionId)
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: serviceFunctionPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output datalakeStorageAccountName string = storageAccountDataLake.name
