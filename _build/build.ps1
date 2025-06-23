# Config
$scriptName     = "RPCL.ahk"
$baseExeName    = "RPCS3-PCL"
$finalExeName   = "RPCL"
$wavName        = "GOOD_MORNING.wav"
$resourceRc     = "add_sound.rc"
$ahk2exePath    = "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
$resHackerPath  = "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe"
$versionFile    = "version.txt"
$versionTpl     = "version_template.txt"
$iconPath       = "icon.ico"
$filesToZip     = @("README.txt", "rpcl3.ini", "LICENSE")
$versionDat     = "version.dat"

# Timestamp
$timestamp      = Get-Date -Format "yyyyMMdd_HH"
$finalExe       = "$finalExeName`_$timestamp.exe"
$zipName        = "$finalExeName`_$timestamp.zip"

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Pre-build tests
Write-Host "🧪 Running pre-build checks..."
if (-not (Test-Path $scriptName)) { Write-Error "Missing $scriptName"; exit 1 }
if (-not (Test-Path $wavName)) { Write-Error "Missing $wavName"; exit 1 }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Error "Git not found"; exit 1 }

# AutoHotkey syntax check (compile only)
Write-Host "🧾 Checking AHK syntax..."
& $ahk2exePath /in $scriptName /check /bin AutoHotkeyU64.exe
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Syntax check failed."
    exit 1
}

# Generate version.dat
$timestamp | Set-Content $versionDat

# Create version.txt from template
Copy-Item $versionTpl $versionFile -Force
(Get-Content $versionFile) -replace '%%DATETIME%%', $timestamp | Set-Content $versionFile

# Cleanup old build files
Remove-Item "$baseExeName.exe","$finalExe","$resourceRc","build.log","$zipName" -ErrorAction SilentlyContinue

# Compile
Write-Host "🔨 Compiling $scriptName..."
& $ahk2exePath /in $scriptName /out "$baseExeName.exe" /bin AutoHotkeyU64.exe /icon $iconPath /versioninfo $versionFile
if (-not (Test-Path "$baseExeName.exe")) {
    Write-Error "❌ Compilation failed."
    exit 1
}

# Embed WAV
"RCDATA GOOD_MORNING $wavName" | Set-Content $resourceRc
Write-Host "🎵 Embedding sound..."
& $resHackerPath -open "$baseExeName.exe" -save "$finalExe" -action addoverwrite -res $resourceRc -log build.log
if (-not (Test-Path "$finalExe")) {
    Write-Error "❌ Failed to embed WAV."
    exit 1
}

# Cleanup
Remove-Item $resourceRc, "build.log" -ErrorAction SilentlyContinue

# Zip
Write-Host "📦 Packaging ZIP: $zipName..."
$allFiles = @($finalExe, $versionDat) + $filesToZip
Compress-Archive -Path $allFiles -DestinationPath $zipName -Force

# Log build
"[$timestamp] Built $finalExe with embedded $wavName" | Add-Content "changelog.txt"

# Git commit, tag, and push
#Write-Host "🔖 Committing changelog and tagging version..."
#git add changelog.txt $versionDat
#git commit -m "Build $timestamp"
#git tag "v$timestamp"
#git push origin --tags
#git push

Write-Host "✅ Build, commit, tag, and push complete: $zipName"
