param vmssName string
param location string

resource natGateway 'Microsoft.Network/natGateways@2024-07-01' = {
  name: '${vmssName}-nat'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: publicIp.id
      }
    ]
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: '${vmssName}-nat-ip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

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
          natGateway: {
            id: natGateway.id
          }
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
