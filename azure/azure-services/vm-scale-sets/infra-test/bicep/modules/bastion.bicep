// Bicep module for Azure Bastion Development SKU
param vnetId string
param location string

resource bastion 'Microsoft.Network/bastionHosts@2024-07-01' = {
  name: 'vmss-bastion'
  location: location
  sku: {
    name: 'Developer'
  }
  properties: {
    virtualNetwork: {id: vnetId}
  }
}
