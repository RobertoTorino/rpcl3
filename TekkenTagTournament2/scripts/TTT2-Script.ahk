; YouTube: @game_play267
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance force

Run, rpcs3.exe --no-gui --fullscreen "dev_hdd0/game/SCEEXE000/EBOOT.BIN"

; Keep script running until Esc is pressed
return

Esc::
    MsgBox, ESC pressed!
    SendInput, !{f4}
    Process, Close, rpcs3.exe
    RunWait, taskkill /im "rpcs3.exe" /F,, Hide
    ExitApp
return
