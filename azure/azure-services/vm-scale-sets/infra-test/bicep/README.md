# VM Scale Sets - Infra Test

## Provision the infrastructure

Set the variables and execute in a bash shell.

```bash
rgName="vmss-infra-test"
adminUsername=""
adminPassword=""

az group create -n $rgName -l "sweden central"
az deployment group create --resource-group $rgName --template-file bicep/main.bicep --parameters adminUsername="$adminUsername" adminPassword="$adminPassword"
```


## Clean up

```bash
# kill the resource group and all resources in it
az group delete -n $rgName -y
```