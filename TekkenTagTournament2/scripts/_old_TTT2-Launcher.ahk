; YouTube: @game_play267
; Launcher for the Arcade versions of RPCS3

; Auto-elevate to run as Administrator
full_command_line := DllCall("GetCommandLine", "str")
if not A_IsAdmin {
    try {
        Run *RunAs "%A_AhkPath%" /f "%A_ScriptFullPath%"
    } catch {
        MsgBox, 16, Elevation Failed, This script needs to be run as administrator.
    }
    ExitApp
}

#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance force

; Log system info on startup
Log("INFO", "Launcher started (elevated)")
Log("INFO", "User: " A_UserName ", OS: " A_OSVersion ", Arch: " (A_Is64bitOS ? "64-bit" : "32-bit"))

; Launch RPCS3 with PowerShell script to set priority initially
Run, powershell.exe -ExecutionPolicy Bypass -File "RPCS3_SetPriority.ps1"

; Show GUI for priority management
Gui, Font, s10, Segoe UI Emoji
Gui, Add, Text,, Current Priority:
Gui, Add, Text, vCurrentPriorityText w200, Checking...
Gui, Add, DropDownList, vPriorityChoice w200, Idle|Below Normal|Normal|Above Normal|High|Realtime
Gui, Add, Button, gSetPriority w150 h30, % Chr(0x2728) " Set Priority"    ; ✨
Gui, Add, Button, gKillRPCS3 w150 h30, % Chr(0x26A0) " Kill RPCS3"        ; ⚠
Gui, Add, Button, gRestartRPCS3 w150 h30, % Chr(0x21BB) " Restart RPCS3"  ; ↻
Gui, Add, Button, gViewLog w150 h30, % Chr(0x1F50D) " View Log"  ; 🔍
Gui, Add, StatusBar
SB_SetText("RPCS3 Launcher Ready.")
Gui, Show, , RPCS3 Priority Control

; Timer to update priority display
SetTimer, UpdatePriority, 2000
return

SetPriority:
    Gui, Submit, NoHide
    priorityCode := ""
    if (PriorityChoice = "Idle")
        priorityCode := "L"
    else if (PriorityChoice = "Below Normal")
        priorityCode := "B"
    else if (PriorityChoice = "Normal")
        priorityCode := "N"
    else if (PriorityChoice = "Above Normal")
        priorityCode := "A"
    else if (PriorityChoice = "High")
        priorityCode := "H"
    else if (PriorityChoice = "Realtime")
        priorityCode := "R"

    Process, Exist, rpcs3.exe
    if (ErrorLevel) {
        Process, Priority, %ErrorLevel%, %priorityCode%
        TrayTip, RPCS3 Priority, Set to %PriorityChoice%, 2
        Log("INFO", "Set RPCS3 priority to " . PriorityChoice)
    } else {
        TrayTip, RPCS3 Priority, RPCS3 not running., 2
        Log("WARN", "Attempted to set priority, but RPCS3 is not running.")
    }
return

UpdatePriority:
    Process, Exist, rpcs3.exe
    if (!ErrorLevel) {
        GuiControl,, CurrentPriorityText, Not running
        GuiControl, Disable, PriorityChoice
        GuiControl, Disable, Set Priority
        return
    }

    pid := ErrorLevel
    current := GetPriority(pid)

    GuiControl,, CurrentPriorityText, %current%

    global lastPriority
    if (current != lastPriority) {
        GuiControl,, PriorityChoice, %current%
        lastPriority := current
    }

    GuiControl, Enable, PriorityChoice
    GuiControl, Enable, Set Priority
return

GetPriority(pid) {
    try {
        wmi := ComObjGet("winmgmts:")
        query := "Select Priority from Win32_Process where ProcessId=" pid
        for proc in wmi.ExecQuery(query)
            return MapPriority(proc.Priority)
        return "Unknown"
    } catch e {
        Log("ERROR", "Failed to get priority: " e.Message)
        return "Error"
    }
}

MapPriority(val) {
    if (val = 64)
        return "Idle"
    if (val = 16384)
        return "Below Normal"
    if (val = 32)
        return "Normal"
    if (val = 32768)
        return "Above Normal"
    if (val = 128)
        return "High"
    if (val = 256)
        return "Realtime"
    return "Unknown (" val ")"
}

KillRPCS3:
    KillAllProcesses()
	TrayTip, RPCS3, Killed all RPCS3 processes., 2
    Log("INFO", "Killed RPCS3, PowerShell, and AHK processes.")
    ExitApp
return

RestartRPCS3:
    RunWait, taskkill /im rpcs3.exe /F,, Hide
    Sleep, 1000
    Run, powershell.exe -ExecutionPolicy Bypass -File "RPCS3_SetPriority.ps1"
    TrayTip, RPCS3, RPCS3 Restarted., 2
    Log("INFO", "Restarted RPCS3.")
return

ViewLog:
    Run, notepad.exe "%A_ScriptDir%\launcher.log"
    Log("INFO", "Opened log file in Notepad.")
return

GuiClose:
GuiEscape:
    Gui, Hide
    Log("INFO", "GUI closed or hidden.")
return

Esc::
    TrayTip, RPCS3 Launcher, ESC pressed. Killing all processes..., 2
    Log("WARN", "ESC pressed. Killing all processes and exiting.")
    KillAllProcesses()
    ExitApp
return

KillAllProcesses() {
    RunWait, taskkill /im rpcs3.exe /F,, Hide
    RunWait, taskkill /im powershell.exe /F,, Hide
    RunWait, taskkill /im autohotkey.exe /F,, Hide
    Log("INFO", "KillAllProcesses executed.")
}

Log(level, msg) {
    FormatTime, timestamp,, yyyy-MM-dd HH:mm:ss
    FileAppend, [%timestamp%] [%level%] %msg%`n, %A_ScriptDir%\launcher.log
}
