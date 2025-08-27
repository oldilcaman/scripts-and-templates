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

## Troubleshooting

## Get infon latest model

```bash
# Get info of the model
az vmss show \
  --resource-group $rgName \
  --name 'vmss-servernameapi'

# Get info of a specific VM
az vmss get-instance-view \
  --resource-group $rgName \
  --name 'vmss-servernameapi' \
  --instance-id 0


# Compare key fields: Look at differences in:
# * OS image version (storageProfile.imageReference.version)
# * Extensions (e.g., missing or outdated provisioningState)
# * Custom script or configuration
# * VM size or SKU
# * Tags or metadata

```


### Check that the latest model has been applied

```bash
#!/bin/bash

RESOURCE_GROUP=$rgName
VMSS_NAME='vmss-servernameapi'

echo "=== Checking VMSS Instances for Latest Model ==="

# Get instance info
az vmss list-instances \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VMSS_NAME" \
  --query "[].{Instance:instanceId, LatestModelApplied:latestModelApplied}" \
  --output tsv | while read INSTANCE_ID MODEL_STATUS; do
    if [ "$MODEL_STATUS" == "true" ]; then
        echo "✅ Instance $INSTANCE_ID is running the latest model."
    else
        echo "❌ Instance $INSTANCE_ID is NOT running the latest model."
    fi
done

```

### Troubleshoot the Custom Script Extension

```bash
# Get status of the extensions
az vmss extension list \
  --resource-group $rgName \
  --vmss-name vmss-servernameapi \
  --query "[].{Name:name, ProvisioningState:provisioningState, Type:type, Status:instanceView.statuses}"

# Get status for the extension on the instance
az vmss list-instances \
  --resource-group $rgName \
  --name vmss-servernameapi \
  --query "[].{ID:instanceId, Name:osProfile.computerName}"

az vmss get-instance-view \
  --resource-group $rgName \
  --name vmss-servernameapi \
  --instance-id 0 \
  --query "extensions[].statuses"


az vmss list-instances \
  --resource-group "$rgName" \
  --name "vmss-servernameapi" \
  --query "[].instanceId" -o tsv | while read instanceId; do
    echo "🔍 Checking instance $instanceId..."
    az vmss get-instance-view \
      --resource-group "$rgName" \
      --name "vmss-servernameapi" \
      --instance-id "$instanceId" \
      --query "extensions[].{Name:name, Status:statuses[-1].displayStatus, Message:statuses[-1].message}" \
      -o table
done

az vmss get-instance-view \
  --resource-group $rgName \
  --name 'vmss-servernameapi' \
  --instance-id 2 \
  --query "extensions"



# Reapply the latest model (and the custom script extension ) on all VMs in VMSS
az vmss update-instances \
  --resource-group $rgName \
  --name vmss-servernameapi \
  --instance-ids "*"


```


### Troubleshoot log files on the VM in the VMSS

```powershell
Write-Host "=== Azure Custom Script Extension Diagnostic ==="

# Check extension status
Write-Host "`n[1] Extension Status:"
$statusPath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\*\Status"
if (Test-Path $statusPath) {
    Get-Content $statusPath
} else {
    Write-Host "No status file found."
}

# Check logs
Write-Host "`n[2] Extension Logs:"
$logPath = "C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension"
if (Test-Path $logPath) {
    Get-ChildItem $logPath -Recurse | Where-Object { $_.Name -like "*.log" } | ForEach-Object {
        Write-Host "`nLog: $($_.FullName)"
        Get-Content $_.FullName -Tail 20
    }
} else {
    Write-Host "No log directory found."
}

# Check network connectivity
Write-Host "`n[3] Network Connectivity:"
Test-NetConnection -ComputerName "acs-mirror.azureedge.net" -Port 443

# Manual file download test
Write-Host "`n[4] Manual File Download Test:"
$testUrl = "https://raw.githubusercontent.com/oldilcaman/scripts-and-templates/refs/heads/main/azure/azure-services/vm-scale-sets/infra-test/custom-script-extension/deploy-servernameapi.ps1"
$outputFile = "$env:TEMP\test-download.ps1"
Invoke-WebRequest -Uri $testUrl -OutFile $outputFile
if (Test-Path $outputFile) {
    Write-Host "Download succeeded: $outputFile"
} else {
    Write-Host "Download failed."
}

Write-Host "`n[5] Done. Review logs and errors above."

```


## Clean up

```bash
# kill the resource group and all resources in it
az group delete -n $rgName -y
```