
Start-Transcript -Path "C:\cse-log.txt" -Append

# Stop the process if it's running
try {
    $pidFile = "C:\ServerNameApi\dotnet.pid"

    if (Test-Path $pidFile) {
        $targetPid = Get-Content $pidFile
        try {
            Stop-Process -Id $targetPid -Force
            Write-Output "✅ Process with ID $targetPid was successfully stopped."

            # Delete the PID file
            Remove-Item $pidFile -Force
            Write-Output "🗑️ PID file deleted."

        } catch {
            Write-Output "⚠️Process with ID $targetPid could not be stopped. It may not exist or is already terminated."
        }
    } else {
        Write-Output "📁 PID file not found. No process to stop."
    }
} catch {
    Write-Output "❌ Unexpected error occurred whild trying to stop the process: $_"
}

# Install .net
try {
    $targetVersion = "9.0.304"
    $installedVersions = & dotnet --list-sdks 2>$null | ForEach-Object {
        ($_ -split "\s+\[")[0]
    }

    if ($installedVersions -contains $targetVersion) {
        Write-Output "✅ .NET SDK version $targetVersion is already installed. Skipping installation."
    } else {
        Write-Output "📦 Installing .NET SDK version $targetVersion..."

        $dotnetSdkInstaller = "https://builds.dotnet.microsoft.com/dotnet/Sdk/$targetVersion/dotnet-sdk-$targetVersion-win-x64.exe"
        $installerPath = "C:\dotnet-sdk-installer.exe"

        try {
            Invoke-WebRequest -Uri $dotnetSdkInstaller -OutFile $installerPath -ErrorAction Stop
            Start-Process $installerPath -ArgumentList "/quiet" -Wait
            Write-Output "✅ Installation of .NET SDK $targetVersion completed."
        } catch {
            Write-Output "❌ Failed to download or install .NET SDK ${targetVersion}: $_"
        }
    }
} catch {
    Write-Output "⚠️ Unexpected error occurred: $_"
}

# Open the port in the firewall
try {
    $ruleName = "Allow Port 5000 for ServerNameApi"
    $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

    if ($null -eq $existingRule) {
        Write-Output "🔐 Firewall rule '$ruleName' not found. Creating rule..."

        New-NetFirewallRule -DisplayName $ruleName `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort 5000 `
            -Action Allow

        Write-Output "✅ Firewall rule '$ruleName' created successfully."
    } else {
        Write-Output "🛡️ Firewall rule '$ruleName' already exists. No action taken."
    }
} catch {
    Write-Output "❌ Unexpected error while managing firewall rule: $_"
}


try {
    
    # Download published ServerNameAPI zip from Azure Storage or GitHub
    Invoke-WebRequest -Uri "https://github.com/peterlil/script-and-templates/releases/download/vmss-scale-sets-ServerNameApi-v0.1/ServerNameApi-v0.1.zip" -OutFile "C:\ServerNameApi.zip"
    Expand-Archive -Path "C:\ServerNameApi.zip" -DestinationPath "C:\ServerNameApi" -Force

    # Start the API (as a background process)
    $proc = Start-Process "C:\Program Files\dotnet\dotnet.exe" -ArgumentList "C:\ServerNameApi\ServerNameApi.dll" -WindowStyle Hidden -PassThru
    $proc.Id | Out-File "C:\ServerNameApi\dotnet.pid"

    # Optional: log that the process was started
    Write-Output "ServerNameApi started, waiting for initialization..."

    # Add a short delay to ensure the process has time to spin up
    Start-Sleep -Seconds 10

    $proc = Get-Process -Name "dotnet" -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Output "dotnet process is running."
    } else {
        Write-Error "dotnet process failed to start."
    }

} catch {
    Write-Error "Script failed: $_"
}


Stop-Transcript
