#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 2
#SingleInstance Force
#NoTrayIcon

videoFolder := A_ScriptDir . "\rpcl3_captures"
playerWidth := 515
playerHeight := 355
title := "RPCL3 Video Player - " . Chr(169) . " " . A_YYYY . " - Philip"

Gui, Color, 24292F
Gui, +AlwaysOnTop
Gui, Font, s10 q5 Bold, Segoe UI Emoji

Gui, Add, Progress, x0 y0 w515 h4 0x10 BackgroundFFCC66 Disabled
Gui, Add, ListView, vVideoList gVideoListClick BackgroundTrans cCCCCCC x0 y1 w515 h100 AltSubmit, Filename|Date Modified
Gui, Font, cCCCCCC s9 q5 bold, Segoe UI Emoji
Gui, Add, Progress,  x0 y99 w515 h1 0x10 BackgroundFFCC66 Disabled
Gui, Add, Text,      x0 y100 w95 h23 gRefreshList BackgroundTrans cCCCCCC +Center +0x200 Border, Refresh
Gui, Add, Text,     x95 y100 w95 h23 gDeleteVideo BackgroundTrans cCCCCCC +Center +0x200 Border, Delete
Gui, Add, Text,    x190 y100 w95 h23 gCopyVideo BackgroundTrans cCCCCCC +Center +0x200 Border, Copy
Gui, Add, Progress, x0 y124 w515 h1 0x10 BackgroundFFCC66 Disabled

LV_ModifyCol(1, 310)
LV_ModifyCol(2, 200)

Gui, Add, Progress, x0 y479 w515 h4 0x10 BackgroundFFCC66 Disabled
Gui, Add, ActiveX, x0 y125 w%playerWidth% h%playerHeight% vWMP, WMPlayer.OCX
WMP.uiMode := "full"
;Gui, Show, , Mini Video Player

WMP.stretchToFit := true
WMP.Enabled := true
WMP.Url := videoPath

; Allow moving the embedded player
Gui, +LastFound
; Populate the ListView
Gosub, RefreshList

Gui, Show, w515 h482, RPCL3 %title%
return

; --- Refresh the ListView ---
RefreshList:
    LV_Delete()
    Loop, Files, %videoFolder%\*.mp4
    {
        FileGetTime, modified, %A_LoopFileFullPath%, M
        FormatTime, modStr, %modified%, yyyy-MM-dd HH:mm:ss
        LV_Add("", A_LoopFileName, modStr)
    }
return

; --- On ListView Double Click ---
VideoListClick:
    if (A_GuiEvent = "DoubleClick") {
        LV_GetText(selectedFile, A_EventInfo, 1)
        videoPath := videoFolder "\" selectedFile
        if FileExist(videoPath) {
            WMP.URL := videoPath
            WMP.Controls.play()
        } else {
            MsgBox, 48, File Not Found, Could not find:`n%videoPath%
        }
    }
return


; --- Delete selected video ---
DeleteVideo:
    Gui, Submit, NoHide
    Gui, ListView, VideoList
    LV_GetText(toDelete, LV_GetNext(), 1)
    if toDelete {
        full := videoFolder "\" toDelete

        ; Get main window position
        WinGetPos, mainX, mainY, mainWidth,, A

        ; Create custom dialog
        Gui, ConfirmDelete:New
        Gui, ConfirmDelete:Add, Text,, Are you sure you want to delete "%toDelete%"?
        Gui, ConfirmDelete:Add, Button, w80 gConfirmDeleteYes Default, &Yes
        Gui, ConfirmDelete:Add, Button, x+10 w80 gConfirmDeleteNo, &No

        ; Position to the right of main window
        dialogX := mainX + mainWidth + 20
        Gui, ConfirmDelete:Show, x%dialogX% y%mainY% Autosize, Confirm Delete
    }
return

ConfirmDeleteYes:
    FileRecycle, %full%
    Gosub, RefreshList
    Gui, ConfirmDelete:Destroy
return

ConfirmDeleteNo:
    Gui, ConfirmDelete:Destroy
return


; --- Copy selected video to another folder ---
CopyVideo:
    Gui, Submit, NoHide
    Gui, ListView, VideoList
    LV_GetText(toCopy, LV_GetNext(), 1)
    if toCopy {
        global full := videoFolder "\" toCopy

        ; Get main window position
        WinGetPos, mainX, mainY, mainWidth,, A

        ; Calculate dialog position (right of main window)
        dialogX := mainX + mainWidth + 20

        ; Create and show custom dialog
        Gui, CopyDialog:New
        Gui, CopyDialog:Add, Text,, Select target folder to copy to:
        Gui, CopyDialog:Add, Edit, w300 vTargetFolder
        Gui, CopyDialog:Add, Button, w80 gBrowseFolder, &Browse...
        Gui, CopyDialog:Add, Button, w80 x+10 gConfirmCopy Default, &Copy
        Gui, CopyDialog:Add, Button, w80 x+10 gCancelCopy, &Cancel
        Gui, CopyDialog:Show, x%dialogX% y%mainY%, Copy Video
    }
return

BrowseFolder:
    ; Minimize main window temporarily
    WinMinimize, ahk_id %CopyVideoHwnd%

    ; Show browse dialog
    FileSelectFolder, selectedFolder,, 3, Select target folder

    ; Restore main window
    WinRestore, ahk_id %CopyVideoHwnd%
    WinActivate, ahk_id %CopyVideoHwnd%

    if selectedFolder
    {
        GuiControl,, TargetFolder, %selectedFolder%
    }
return

ConfirmCopy:
    Gui, Submit
    if (TargetFolder != "")
    {
        FileCopy, %full%, %TargetFolder%\%toCopy%
    }
    Gui, CopyDialog:Destroy
return

CancelCopy:
    Gui, CopyDialog:Destroy
return


; ─── Custom tray tip function ────────────────────────────────────────────────────────────────────
CustomTrayTip(Text, Icon := 1) {
    ;Parameters:
    ;Text  - Message to display
    ;Icon  - 0=None, 1=Info, 2=Warning, 3=Error (default=1)
    static Title := "RPCL3 Launcher"
    ;Validate icon input (clamp to 0-3 range)
    Icon := (Icon >= 0 && Icon <= 3) ? Icon : 1
    ;16 = No sound (bitwise OR with icon value)
    TrayTip, %Title%, %Text%, , % Icon|16
}

GuiClose:
ExitApp
