Start-Transcript -Path "C:\cse-log.txt" -Append

# --- Stop Existing ServerNameApi Process ---
try {
    $pidFile = "C:\ServerNameApi\dotnet.pid"
    if (Test-Path $pidFile) {
        $targetPid = Get-Content $pidFile
        try {
            Stop-Process -Id $targetPid -Force
            Write-Output "✅ Process with ID $targetPid stopped."
            Remove-Item $pidFile -Force
            Write-Output "🗑️ PID file deleted."
        } catch {
            Write-Output "⚠️ Could not stop process with ID ${targetPid}: $_"
        }
    } else {
        Write-Output "📁 No PID file found. No process to stop."
    }
} catch {
    Write-Output "❌ Error while stopping process: $_"
}

# --- Install .NET SDK if Missing ---
try {
    $targetVersion = "9.0.304"
    $dotnetPath = "C:\Program Files\dotnet\dotnet.exe"
    $installerPath = "C:\dotnet-sdk-installer.exe"
    $dotnetInstalled = $false

    if (Test-Path $dotnetPath) {
        $installedVersions = & $dotnetPath --list-sdks 2>$null | ForEach-Object {
            ($_ -split "\s+\[")[0]
        }
        if ($installedVersions -contains $targetVersion) {
            Write-Output "✅ .NET SDK $targetVersion already installed."
            $dotnetInstalled = $true
        }
    }

    if (-not $dotnetInstalled) {
        Write-Output "📦 Installing .NET SDK $targetVersion..."
        $dotnetSdkInstaller = "https://builds.dotnet.microsoft.com/dotnet/Sdk/$targetVersion/dotnet-sdk-$targetVersion-win-x64.exe"
        Invoke-WebRequest -Uri $dotnetSdkInstaller -OutFile $installerPath -ErrorAction Stop
        $process = Start-Process $installerPath -ArgumentList "/quiet" -Wait -PassThru
        Write-Output "✅ Installer exited with code: $($process.ExitCode)"
    }
} catch {
    Write-Output "❌ Error during .NET SDK installation: $_"
}

# --- Open Port 5000 in Windows Firewall ---
try {
    $ruleName = "Allow Port 5000 for ServerNameApi"
    $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    if ($null -eq $existingRule) {
        Write-Output "🔐 Creating firewall rule for port 5000..."
        New-NetFirewallRule -DisplayName $ruleName `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort 5000 `
            -Action Allow
        Write-Output "✅ Firewall rule created."
    } else {
        Write-Output "🛡️ Firewall rule already exists. Skipping."
    }
} catch {
    Write-Output "❌ Error managing firewall rule: $_"
}

# --- Download and Launch ServerNameApi ---
try {
    $zipUrl = "https://github.com/peterlil/script-and-templates/releases/download/vmss-scale-sets-ServerNameApi-v0.1/ServerNameApi-v0.1.zip"
    $zipPath = "C:\ServerNameApi.zip"
    $extractPath = "C:\ServerNameApi"

    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -ErrorAction Stop
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

    $proc = Start-Process "C:\Program Files\dotnet\dotnet.exe" `
        -ArgumentList "$extractPath\ServerNameApi.dll" `
        -WindowStyle Hidden -PassThru

    $proc.Id | Out-File "$extractPath\dotnet.pid"
    Write-Output "🚀 ServerNameApi started with PID $($proc.Id). Waiting for initialization..."
    Start-Sleep -Seconds 10

    if (-not $proc.HasExited) {
        Write-Output "✅ dotnet process is running."
    } else {
        Write-Output "❌ dotnet process exited prematurely."
    }
} catch {
    Write-Output "❌ Error launching ServerNameApi: $_"
}

Stop-Transcript