# YouTube: @game_play267
# Launch RPCS3 with EBOOT and monitor ESC to kill all rpcs3.exe instances
# Use esc inside the Powershell window

$exePath = ".\rpcs3.exe"
$ebootPath = "dev_hdd0\game\SCEEXE000\EBOOT.BIN"
$arguments = "--no-gui --fullscreen `"$ebootPath`""

# Launch RPCS3
try {
    Write-Host "Launching RPCS3..."
    Start-Process -FilePath $exePath -ArgumentList $arguments -WorkingDirectory (Get-Location)
    Start-Sleep -Seconds 2
} catch {
    Write-Error "Failed to launch RPCS3."
    exit
}

# Set priority to realtime for all rpcs3.exe processes
Get-Process rpcs3 -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $_.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::RealTime
        Write-Host "Set process ID $($_.Id) to Realtime."
    } catch {
        Write-Warning "Could not set priority on PID $($_.Id)."
    }
}

Write-Host "`nMonitoring RPCS3. Press ESC to terminate all rpcs3.exe processes..."

# Loop for ESC key
while ($true) {
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq 'Escape') {
            Write-Host "ESC pressed. Killing all RPCS3 processes..."
            Stop-Process -Name "rpcs3" -Force -ErrorAction SilentlyContinue
            break
        }
    }

    # Keep priorities realtime
    Get-Process rpcs3 -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            if ($_.PriorityClass -ne [System.Diagnostics.ProcessPriorityClass]::RealTime) {
                $_.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::RealTime
                Write-Host "Reset priority to Realtime for PID $($_.Id)."
            }
        } catch {
            # Process may have exited
        }
    }

    Start-Sleep -Milliseconds 500
}

Write-Host "All done. Exiting."
