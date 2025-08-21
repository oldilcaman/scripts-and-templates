
Start-Transcript -Path "C:\cse-log.txt" -Append

try {
    # Download published ServerNameAPI zip from Azure Storage or GitHub
    Invoke-WebRequest -Uri "https://github.com/peterlil/script-and-templates/releases/download/vmss-scale-sets-ServerNameApi-v0.1/ServerNameApi-v0.1.zip" -OutFile "C:\ServerNameApi.zip"
    Expand-Archive -Path "C:\ServerNameApi.zip" -DestinationPath "C:\ServerNameApi"

    # Install .NET if needed (example for .NET 9)
    $dotnetInstaller = "https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/9.0.8/aspnetcore-runtime-9.0.8-win-x64.exe"
    Invoke-WebRequest -Uri $dotnetInstaller -OutFile "C:\dotnet-installer.exe"
    Start-Process "C:\dotnet-installer.exe" -ArgumentList "/quiet" -Wait

    # Start the API (as a background process)
    Start-Process "C:\Program Files\dotnet\dotnet.exe" -ArgumentList "C:\ServerNameApi\ServerNameApi.dll" -WindowStyle Hidden

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
