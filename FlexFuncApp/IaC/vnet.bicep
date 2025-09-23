@description('Enter location for your resources')
@allowed([
  'Sweden Central'
])
param location string

@description('The name of the existing Virtual Network')
param vnetName string

@description('The address prefix for the Virtual Network')
param vnetPrefix string

// @description('The resource group of the existing Virtual Network')
// param vnetResourceGroupName string

@description('The name of the new subnet')
param subnetName string

@description('The address prefix for the new subnet')
param subnetPrefix string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetPrefix
      ]
    }
  }
}

module subnetModule 'subnet.bicep' = {
  name: 'subnetModule'
  params: {
    vnetName: vnetName
    subnetPrefix: subnetPrefix
    subnetName: subnetName
  }
}

output vnetId string = virtualNetwork.id
output subnetId string = subnetModule.outputs.subnetId
