param vmssName string
param location string
param adminUsername string
@secure()
param adminPassword string
param vmssSubnetId string

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: '${vmssName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHttp'
        properties: {
          priority: 1001
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowHttps'
        properties: {
          priority: 1002
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      // {
      //   name: 'Allow-Port-5000'
      //   properties: {
      //     priority: 1003
      //     direction: 'Inbound'
      //     access: 'Allow'
      //     protocol: 'Tcp'
      //     sourcePortRange: '*'
      //     destinationPortRange: '5000'
      //     sourceAddressPrefix: '*'
      //     destinationAddressPrefix: '*'
      //   }
      // }
    ]
  }
}

var lbName = 'vmss-lb'

resource lb 'Microsoft.Network/loadBalancers@2024-07-01' = {
  name: lbName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          subnet: {
            id: vmssSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool'
      }
    ]
    probes: [
      {
        name: 'HealthProbe'
        properties: {
          protocol: 'Http'
          port: 5000
          requestPath: '/health'
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'HttpRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, 'LoadBalancerFrontEnd')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, 'BackendPool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, 'HealthProbe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 5000
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          loadDistribution: 'Default'
        }
      }
    ]
  }
}


resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2024-11-01' = {
  name: vmssName
  location: location
  sku: {
    name: 'Standard_B2s'
    tier: 'Standard'
    capacity: 2
  }
  properties: {
    upgradePolicy: {
      mode: 'Manual'
      // mode: 'Rolling'
      // rollingUpgradePolicy: {
      //   maxBatchInstancePercent: 50
      //   maxUnhealthyInstancePercent: 50
      //   pauseTimeBetweenBatches: 'PT2M'
      // }
    }
    virtualMachineProfile: {
      storageProfile: {
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2025-datacenter'
          version: 'latest'
        }
        osDisk: {
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
      }
      osProfile: {
        computerNamePrefix: 'vmss'
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: {
                      id: vmssSubnetId
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: lb.properties.backendAddressPools[0].id  // This should point to your load balancer's backend pool
                      }
                    ]
                  }
                }
              ]
              networkSecurityGroup: {
                id: nsg.id
              }
            }
          }
        ]
      }
    }
    overprovision: true
  }
}

resource customScriptExt 'Microsoft.Compute/virtualMachineScaleSets/extensions@2024-11-01' = {
  name: '${vmss.name}/CustomScriptExtension'
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        // URL to your deployment script, e.g., a PowerShell script in Azure Storage or GitHub
        'https://raw.githubusercontent.com/oldilcaman/scripts-and-templates/refs/heads/main/azure/azure-services/vm-scale-sets/infra-test/custom-script-extension/deploy-servernameapi.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File deploy-servernameapi.ps1'
      timestamp: '2025-08-22T10:16:00Z'
    }
    forceUpdateTag: '20250822c'
  }
}




output vmss object = vmss
output vmssId string = vmss.id
