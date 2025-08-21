param vmssName string
param location string

resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: '${vmssName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'vmss'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'frontend'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

output vnet object = vnet
output vnetId string = vnet.id
output vmssSubnetId string = '${vnet.id}/subnets/vmss'
output frontendSubnetId string = '${vnet.id}/subnets/frontend'
