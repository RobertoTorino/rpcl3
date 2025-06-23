; YouTube: @game_play267
; Launcher for Tekken Tag Tournament 2
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance force

; Paths
rpcs3 := "rpcs3.exe"
eboot := "dev_hdd0\game\SCEEXE000\EBOOT.BIN"
args := "--no-gui --fullscreen """ . eboot . """"

; Launch RPCS3
Run, %ComSpec% /c start "" /b %rpcs3% %args%,, Hide, rpcs3PID

; Wait a moment for the process to start
Sleep, 2000

; Set priority to Realtime
Process, Priority, %rpcs3PID%, R
; Optional: Try setting it twice in case it fails the first time
Sleep, 500
Process, Priority, %rpcs3PID%, R

TrayTip, RPCS3 Launcher, Press ESC to terminate RPCS3, 5

; Monitor for ESC key globally
Esc::
    TrayTip, RPCS3 Launcher, ESC pressed. Killing RPCS3..., 2
    RunWait, taskkill /im rpcs3.exe /F,, Hide
    ExitApp
return