# Download published ServerNameAPI zip from Azure Storage or GitHub
Invoke-WebRequest -Uri "https://github.com/peterlil/script-and-templates/releases/download/vmss-scale-sets-ServerNameApi-v0.1/ServerNameApi-v0.1.zip" -OutFile "C:\ServerNameApi.zip"
Expand-Archive -Path "C:\ServerNameApi.zip" -DestinationPath "C:\ServerNameApi"

# Install .NET if needed (example for .NET 9)
$dotnetInstaller = "https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/9.0.8/aspnetcore-runtime-9.0.8-win-x64.exe"
Invoke-WebRequest -Uri $dotnetInstaller -OutFile "C:\dotnet-installer.exe"
Start-Process "C:\dotnet-installer.exe" -ArgumentList "/quiet" -Wait

# Start the API (as a background process)
Start-Process "dotnet" -ArgumentList "C:\ServerNameApi\ServerNameApi.dll" -WindowStyle Hidden