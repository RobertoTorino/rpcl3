# SetPriority.ps1
# Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned
# Right-click PowerShell and "Run as Administrator".
# Run the script:
# .\Set-ExeRealtimePriority.ps1
# Select the .exe

Add-Type -AssemblyName System.Windows.Forms

function Select-ExeFile {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Executable Files (*.exe)|*.exe"
    $dialog.Title = "Select an executable"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileName
    }
    return $null
}

$exePath = Select-ExeFile
if (-not $exePath) {
    Write-Host "No file selected. Exiting..."
    exit
}

# Start the process and capture it
$process = Start-Process -FilePath $exePath -PassThru
Start-Sleep -Seconds 1

try {
    $process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::RealTime
    Write-Host "Set process '$($process.ProcessName)' to Realtime priority."
} catch {
    Write-Error "Failed to set priority. Try running as Administrator."
    exit
}

# Monitor and keep the priority as Realtime
Write-Host "Monitoring process to keep Realtime priority (Press Ctrl+C to stop)..."
while (!$process.HasExited) {
    try {
        if ($process.PriorityClass -ne [System.Diagnostics.ProcessPriorityClass]::RealTime) {
            $process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::RealTime
            Write-Host "Reset priority to Realtime."
        }
    } catch {
        Write-Warning "Could not check/set priority. The process may have exited."
    }
    Start-Sleep -Seconds 2
}

Write-Host "Process exited. Done."
