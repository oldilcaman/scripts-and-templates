param vmssName string = 'vmss-servernameapi'
param location string = resourceGroup().location
param adminUsername string
@secure()
param adminPassword string

module networkMod 'modules/network.bicep' = {
  name: 'network'
  params: {
    vmssName: vmssName
    location: location
  }
}

module vmssMod 'modules/vmss.bicep' = {
  name: 'vmss'
  params: {
    vmssName: vmssName
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmssSubnetId: networkMod.outputs.vmssSubnetId
  }
}

module frontendVmMod 'modules/frontend-vm.bicep' = {
  name: 'frontendVm'
  params: {
    location: location
    vmName: 'frontend-vm'
    vmUsername: adminUsername
    vmPassword: adminPassword
    frontendSubnetId: networkMod.outputs.frontendSubnetId
  }
}

module bastionMod 'modules/bastion.bicep' = {
  name: 'bastion'
  params: {
    vnetId: networkMod.outputs.vnetId
    location: location
  }
}

output vmssId string = vmssMod.outputs.vmssId
