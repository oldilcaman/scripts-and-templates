Start-Transcript -Path "C:\manual-management-log.txt" -Append

# --- Stop Existing ServerNameApi Process ---
try {
    $pidFile = "C:\ServerNameApi\dotnet.pid"

    if (Test-Path $pidFile) {
        $targetPid = Get-Content $pidFile
        try {
            Stop-Process -Id $targetPid -Force
            Write-Output "Process with ID $targetPid was successfully stopped."

            # Delete the PID file
            Remove-Item $pidFile -Force
            Write-Output "PID file deleted."

        } catch {
            Write-Output "Process with ID $targetPid could not be stopped. It may not exist or is already terminated."
        }
    } else {
        Write-Output "PID file not found. No process to stop."
    }
} catch {
    Write-Output "Unexpected error occurred whild trying to stop the process: $_"
}


try {
      # Start the API (as a background process)
    $env:ASPNETCORE_URLS="http://0.0.0.0:5000"
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
    Write-Error ("Script failed: " + $_)
}


Stop-Transcript
