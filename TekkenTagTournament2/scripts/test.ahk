#SingleInstance Force
#NoEnv
SetBatchLines, -1
DetectHiddenWindows, On
SetTitleMatchMode, 2

; Config
iniFile := A_ScriptDir "\config.ini"
selectedPriority := "High"
priorityList := "Realtime|High|AboveNormal|Normal|BelowNormal|Idle"
IniRead, selectedPriority, %iniFile%, Settings, Priority, High

; Dark Mode
IniRead, darkMode, %iniFile%, Settings, DarkMode, 0
darkBG := darkMode ? "222222" : "FFFFFF"
darkFG := darkMode ? "FFFFFF" : "000000"

Gui, Font, s10, Segoe UI
Gui, Color, %darkBG%

Gui, Add, Text, x20 y20 w200 h20 c%darkFG%, Select RPCS3 Process Priority:
Gui, Add, DropDownList, vPriorityChoice gSetPriority w150 c%darkFG% bg%darkBG%, %priorityList%
GuiControl,, PriorityChoice, %selectedPriority%

Gui, Add, Button, gLaunchRPCS3 x20 y60 w180 h30, Launch RPCS3
Gui, Add, Button, gInstallFirmware x20 y100 w180 h30, Install Firmware
GuiControl, +ToolTip, InstallFirmware, Install official PS3 firmware (.PUP)

Gui, Add, Button, gInstallPackage x20 y140 w180 h30, Install Package (.pkg)
GuiControl, +ToolTip, InstallPackage, Install a PS3 game/package (.pkg)

Gui, Add, Button, gOpenSaveFolder x20 y180 w180 h30, Open Save Folder
GuiControl, +ToolTip, OpenSaveFolder, Open RPCS3 savedata folder

Gui, Add, Button, gOpenConfigFolder x20 y220 w180 h30, Open Config Folder
GuiControl, +ToolTip, OpenConfigFolder, Open RPCS3 config/data folder

Gui, Add, Button, gCheckVersion x20 y260 w180 h30, Check RPCS3 Version
Gui, Add, Button, gViewLog x20 y300 w180 h30, View Log File
Gui, Add, Button, gToggleDarkMode x20 y340 w180 h30, Toggle Dark Mode

Gui, Add, Button, gShowHelp x20 y380 w180 h30, Help / About
Gui, Add, Button, gExitLauncher x20 y420 w180 h30, Exit Launcher

Gui, Add, Text, vStaticCPU x220 y20 w200 h20 c%darkFG%
Gui, Add, Text, vStaticRAM x220 y50 w200 h20 c%darkFG%

SetTimer, UpdateStats, 1000
Gui, Show, w440 h480, RPCS3 Launcher
return

; ---------------------------
SetPriority:
GuiControlGet, selectedPriority,, PriorityChoice
IniWrite, %selectedPriority%, %iniFile%, Settings, Priority
return

LaunchRPCS3:
full_command := "Start-Process -Verb RunAs -FilePath rpcs3.exe -WindowStyle Hidden -Priority '" selectedPriority "'"
RunWait, %ComSpec% /c powershell -Command "%full_command%", , Hide
return

InstallFirmware:
FileSelectFile, firmwarePath, 3,, Select PS3 Firmware File (*.PUP), *.PUP
if firmwarePath
{
    RunWait, rpcs3.exe --installfw "%firmwarePath%", , Hide
    MsgBox, 64, Success, Firmware installed.
}
return

InstallPackage:
FileSelectFile, pkgPath, 3,, Select PKG File, *.pkg
if pkgPath
{
    RunWait, rpcs3.exe "%pkgPath%", , Hide
    MsgBox, 64, Success, Package installed.
}
return

OpenSaveFolder:
Run, explorer.exe "%A_AppData%\RPCS3\dev_hdd0\home\00000001\savedata%"
return

OpenConfigFolder:
Run, explorer.exe "%A_AppData%\RPCS3"
return

CheckVersion:
RunWait, rpcs3.exe --version, , Hide
MsgBox, 64, Version Info, (Check console window or log)
return

ViewLog:
logPath := A_AppData "\RPCS3\log.log"
if FileExist(logPath)
    Run, notepad.exe "%logPath%"
else
    MsgBox, 48, Not Found, Log file not found.
return

ToggleDarkMode:
darkMode := !darkMode
IniWrite, %darkMode%, %iniFile%, Settings, DarkMode
Reload
return

ShowHelp:
MsgBox, 64, RPCS3 Launcher Help, 
(
RPCS3 Launcher Script
- Launches with custom process priority
- Shows CPU and RAM usage
- GUI for firmware/pkg install
- Opens common folders

Author: You
Version: 1.0
)
return

ExitLauncher:
ExitApp

UpdateStats:
ComObjGet("winmgmts:root\cimv2").ExecQuery("Select * from Win32_Processor")._NewEnum.Next(cpu)
cpuLoad := cpu.LoadPercentage
GuiControl,, StaticCPU, CPU Usage: %cpuLoad% %

ComObjGet("winmgmts:root\cimv2").ExecQuery("Select * from Win32_OperatingSystem")._NewEnum.Next(os)
totalMem := os.TotalVisibleMemorySize
freeMem := os.FreePhysicalMemory
usedMem := totalMem - freeMem
memUsage := Round((usedMem / totalMem) * 100)
GuiControl,, StaticRAM, Memory Usage: %memUsage% %
return
