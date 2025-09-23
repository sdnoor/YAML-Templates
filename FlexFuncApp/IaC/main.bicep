@description('Enter name of Integration')
param integrationName string

@description('Enter location for your resources')
@allowed([
  'Sweden Central'
])
param location string

@description('Enter location for storage Account')
param locationStorageAccount string

@description('Enter Environment of the resource')
@allowed([
  'Dev'
  'Prod'
])
param environment string

//KeyVault
param keyVaultName string
param keyvaultResourceGroupName string

//Service Plan Sku
param spSkuName string
param spSkuTier string

//VNet and Subnet
@description('The name of the existing Virtual Network')
param vnetName string

@description('The name of the new subnet')
param subnetName string

@description('The address prefix for the new subnet')
param subnetPrefix string

@description('The address prefix for the Virtual Network')
param vnetPrefix string

param storageAccountIntegrationName string

param serviceBusResourceGroup string
param serviceBusSubscriptionId string

param integrationNameStorageAccount string
param integrationNameServiceBus string

//Function App Configurations
param applicationName string

@secure()
param sftpUsernameSecretName string
@secure()
param sftpPasswordSecretName string

//Data Lake
param datalakeName string
param datalakeStorageResourceGroupName string
param datalakeStorageSubscriptionId string

var aiName = toLower('ai-${integrationName}-weu-${environment}')
var funcName = toLower('func-${integrationName}-swc-${environment}')
var storageName = toLower('sto${integrationNameStorageAccount}weu${environment}')


module insights 'insights.bicep' = {
  name: aiName
  params: {
    location: location
    environment: environment
    integrationName: integrationName
  }
}

module storageAccount 'storage.bicep' = {
  name: storageName
  params: {
    locationStorageAccount: locationStorageAccount
    environment: environment
    integrationNameStorageAccount: integrationNameStorageAccount
  }
}

module serviceBus 'servicebus.bicep' = {
  scope: resourceGroup(serviceBusSubscriptionId, serviceBusResourceGroup)
  params: {
    environment: environment
    integrationNameServiceBus: integrationNameServiceBus
    serviceBusResourceGroup: serviceBusResourceGroup
    serviceBusSubscriptionId: serviceBusSubscriptionId
  }
}

module subnet 'subnet.bicep' = {
  params: {
    subnetName: subnetName
    subnetPrefix: subnetPrefix
    vnetName: vnetName
  }
  dependsOn: [
    vnetMedius
  ]
}

module vnetMedius 'vnet.bicep' = {
  params: {
    location: location
    subnetName: subnetName
    subnetPrefix: subnetPrefix
    vnetName: vnetName
    vnetPrefix: vnetPrefix
}
}

module func 'func.bicep' = {
  name: funcName
  params: {
    applicationName: applicationName
    location: location
    aiConnectString: insights.outputs.aiConnectString
    environment: environment
    integrationName: integrationName
    integrationNameStorageAccount: integrationNameStorageAccount
    integrationNameServiceBus: integrationNameServiceBus
    deploymentContainerUrl: '${storageAccount.outputs.storageAccountPrimaryEndpoint}testdeployment'
    vnetSubnetId: subnet.outputs.subnetId
    keyVaultName: keyVaultName
    keyvaultResourceGroupName: keyvaultResourceGroupName
    spSkuName: spSkuName
    spSkuTier: spSkuTier
    sftpUsernameSecretName: sftpUsernameSecretName
    sftpPasswordSecretName: sftpPasswordSecretName
 }
  dependsOn: [
    storageAccount
    insights
    vnetMedius
    subnet
  ]
}

// Assign roles to the Function Apps
module roleAssignments 'roleAssignments.bicep' = {
  name: 'roleAssignments'
  params: {
    storageAccountName: storageAccount.outputs.storageAccountName
    environment: environment
    serviceFunctionPrincipalId: func.outputs.functionPrincipalId
  }
  dependsOn: [
    func
    storageAccount
    serviceBus
  ]
}

module servicebusroleAssignments 'sbroleAssignments.bicep' = {
  scope: resourceGroup(serviceBusSubscriptionId, serviceBusResourceGroup)
  params: {
    environment: environment
    serviceBusName: serviceBus.outputs.serviceBusName
    serviceBusResourceGroup: serviceBusResourceGroup
    serviceFunctionPrincipalId: func.outputs.functionPrincipalId
  }
  dependsOn: [
    func
    serviceBus
  ]
}

module datalakeRoleAssignment 'datalakeRoleAssignments.bicep' = {
  scope: resourceGroup(datalakeStorageSubscriptionId, datalakeStorageResourceGroupName)
  params: {
    datalakeName: datalakeName
    datalakeStorageSubscriptionId: datalakeStorageSubscriptionId
    // datalakeStorageResourceGroupName: datalakeStorageResourceGroupName
    serviceFunctionPrincipalId: func.outputs.functionPrincipalId
  }
  dependsOn: [
    func
  ]
}
