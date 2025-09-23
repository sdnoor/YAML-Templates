@description('Enter Environment of the resource')
@allowed([
  'Dev'
  'Prod'
])
param environment string

param storageAccountName string
param serviceFunctionPrincipalId string



// Storage Blob Data Contributor Role
resource storageBlobDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

// Storage Queue Data Contributor Role
resource storageQueueDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
}


// Reference to the Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' existing = {
  name: storageAccountName
}

// Assign Storage Blob Data Contributor Role to the Service Function
resource serviceFunctionRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, serviceFunctionPrincipalId, storageBlobDataContributorRole.id)
  properties: {
    roleDefinitionId: storageBlobDataContributorRole.id
    principalId: serviceFunctionPrincipalId
    principalType: 'ServicePrincipal'
  }
}


// Assign Storage Queue Data Contributor Role to the Service Function
resource serviceFunctionQueueRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, serviceFunctionPrincipalId, storageQueueDataContributorRole.id)
  properties: {   
    roleDefinitionId: storageQueueDataContributorRole.id
    principalId: serviceFunctionPrincipalId
    principalType: 'ServicePrincipal'
  }
}


