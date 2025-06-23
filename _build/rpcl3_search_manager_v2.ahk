#SingleInstance Force
#NoEnv
#Include %A_ScriptDir%\SQLiteDB.ahk

db := new SQLiteDB()
if !db.OpenDB(A_ScriptDir . "\games.db") {
    err := db.ErrorMsg
    MsgBox, 16, DB Error, Failed to open DB.`n%err%
    ExitApp
}

; Create integrated GUI
Gui, Font, s10, Segoe UI

; Filter section at the top
Gui, Add, GroupBox, x10 y10 w380 h80, Filters
Gui, Add, CheckBox, vFilterFavorite x20 y30, Favorite
Gui, Add, CheckBox, vFilterPlayed x100 y30, Played
Gui, Add, CheckBox, vFilterPSN x180 y30, PSN
Gui, Add, CheckBox, vFilterArcadeGame x260 y30, Arcade Games

; Quick access button
Gui, Add, Button, gShowAll x20 y55 w80 h20, Show All

; Search section
Gui, Add, GroupBox, x10 y100 w380 h60, Search
Gui, Add, Text, x20 y120, Game title or ID:
Gui, Add, Edit, vSearchTerm x120 y117 w180 h20
Gui, Add, Button, gSearch x310 y117 w70 h23, Search

; Results section - ListView for better display
Gui, Add, GroupBox, x10 y170 w380 h200, Results
Gui, Add, ListView, vResultsList x20 y190 w360 h150 Grid -Multi AltSubmit gListViewClick, Game ID|Title
LV_ModifyCol(1, 80)
LV_ModifyCol(2, 270)

; Image preview section
Gui, Add, GroupBox, x10 y380 w380 h100, Game Preview
Gui, Add, Picture, vGameIcon x20 y400 w64 h64 gShowLargeImage, ; Small icon preview
Gui, Add, Text, vImageStatus x95 y420, Select a game to see its icon

; Action buttons
Gui, Add, Button, gLaunchGame x200 y400 w80 h30, Launch
Gui, Add, Button, gClearSearch x290 y400 w80 h30, Clear

Gui, Show, w400 h490, Game Search Launcher
return

Search:
    Gui, Submit, NoHide

    ; Get search term
    searchTerm := Trim(SearchTerm)
    if (searchTerm = "") {
        MsgBox, 48, Input Required, Please enter a search term.
        return
    }

    ; Build filters array
    filters := []
    if (FilterFavorite)
        filters.Push("Favorite = 1")
    if (FilterPlayed)
        filters.Push("Played = 1")
    if (FilterPSN)
        filters.Push("PSN = 1")
    if (FilterArcadeGame)
        filters.Push("ArcadeGame = 1")

    ; Build WHERE clause
    whereClause := "WHERE (GameTitle LIKE '%" . StrReplace(searchTerm, "'", "''") . "%' OR GameId LIKE '%" . StrReplace(searchTerm, "'", "''") . "%')"

    if (filters.MaxIndex() > 0)
        whereClause .= " AND " . Join(" AND ", filters)

    ; Execute query - exact same as your working version
    sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1 FROM games " . whereClause . " ORDER BY GameTitle LIMIT 50"

    if !db.GetTable(sql, result) {
        MsgBox, 16, Query Error, % "Query failed:`n" . db.ErrorMsg
        return
    }

    ; Clear and populate ListView
    LV_Delete()

    if (result.RowCount = 0) {
        LV_Add("", "No results found", "")
        ClearImagePreview()
        return
    }

    ; Add results to ListView and store paths
    Loop, % result.RowCount {
        row := ""
        if result.GetRow(A_Index, row) {
            ; Store all the paths in global arrays for later use
            EbootPaths%A_Index% := row[3]
            IconPaths%A_Index% := row[4]
            PicPaths%A_Index% := row[5]
            LV_Add("", row[1], row[2])
        }
    }

    ; Auto-resize columns
    LV_ModifyCol(1, "AutoHdr")
    LV_ModifyCol(2, "AutoHdr")

    ; Clear image preview
    ClearImagePreview()
return

ShowAll:
    Gui, Submit, NoHide

    ; Build filters for Show All (no search term)
    filters := []
    if (FilterFavorite)
        filters.Push("Favorite = 1")
    if (FilterPlayed)
        filters.Push("Played = 1")
    if (FilterPSN)
        filters.Push("PSN = 1")
    if (FilterArcadeGame)
        filters.Push("ArcadeGame = 1")

    ; Build WHERE clause for Show All - same logic as Search but without search term
    if (filters.MaxIndex() > 0) {
        whereClause := "WHERE " . Join(" AND ", filters)
        sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1 FROM games " . whereClause . " ORDER BY GameTitle LIMIT 50"
    } else {
        ; No filters at all - show everything
        sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1 FROM games ORDER BY GameTitle LIMIT 50"
    }

    if !db.GetTable(sql, result) {
        MsgBox, 16, Query Error, % "Query failed:`n" . db.ErrorMsg
        return
    }

    ; Clear and populate ListView - exact same code as Search
    LV_Delete()

    if (result.RowCount = 0) {
        LV_Add("", "No results found", "")
        ClearImagePreview()
        return
    }

    ; Add results to ListView and store paths
    Loop, % result.RowCount {
        row := ""
        if result.GetRow(A_Index, row) {
            ; Store all the paths in global arrays for later use
            EbootPaths%A_Index% := row[3]
            IconPaths%A_Index% := row[4]
            PicPaths%A_Index% := row[5]
            LV_Add("", row[1], row[2])
        }
    }

    ; Auto-resize columns
    LV_ModifyCol(1, "AutoHdr")
    LV_ModifyCol(2, "AutoHdr")

    ; Clear image preview
    ClearImagePreview()
return

ListViewClick:
    ; Handle ListView selection change
    selectedRow := LV_GetNext()
    if (selectedRow > 0) {
        ShowGameIcon(selectedRow)
    } else {
        ClearImagePreview()
    }
return

ShowGameIcon(rowIndex) {
    ; Get the icon path for the selected row
    iconPath := IconPaths%rowIndex%

    if (iconPath != "" && FileExist(iconPath)) {
        ; Update the picture control with the icon
        GuiControl,, GameIcon, %iconPath%
        GuiControl,, ImageStatus, Click icon for larger view

        ; Store current selection for large image display
        CurrentSelectedRow := rowIndex
    } else {
        ; Show placeholder or clear image
        GuiControl,, GameIcon, ; Clear the image
        GuiControl,, ImageStatus, No icon available
        CurrentSelectedRow := 0
    }
}

ShowLargeImage:
    ; Show the larger image in a new window when icon is clicked
    if (CurrentSelectedRow <= 0)
        return

    picPath := PicPaths%CurrentSelectedRow%

    if (picPath = "" || !FileExist(picPath)) {
        MsgBox, 48, Image Not Found, Large image not available for this game.
        return
    }

    ; Create new GUI for large image
    Gui, 2: New, +Resize +MaximizeBox, Game Image
    Gui, 2: Add, Picture, x10 y10, %picPath%
    Gui, 2: Show, w600 h400
return

2GuiClose:
    Gui, 2: Destroy
return

ClearImagePreview() {
    GuiControl,, GameIcon, ; Clear the image
    GuiControl,, ImageStatus, Select a game to see its icon
    CurrentSelectedRow := 0
}

LaunchGame:
    ; Get selected row
    selectedRow := LV_GetNext()
    if (!selectedRow) {
        MsgBox, 48, No Selection, Please select a game from the list.
        return
    }

    ; Get game info
    LV_GetText(gameId, selectedRow, 1)
    LV_GetText(gameTitle, selectedRow, 2)

    ; Get the stored Eboot path
    ebootPath := EbootPaths%selectedRow%

    if (ebootPath = "") {
        MsgBox, 16, Error, Could not find Eboot path for selected game.
        return
    }

    ; Confirm launch
    msg := "Launch this game?`n`nGame ID: " . gameId . "`nTitle: " . gameTitle
    MsgBox, 4, Confirm Launch, %msg%

    IfMsgBox, Yes
    {
        runCommand := "rpcs3.exe --no-gui --fullscreen """ ebootPath """"
        IniWrite, %runCommand%, %A_ScriptDir%\launcher.ini, RUN_GAME, RunCommand
        MsgBox, 64, Success, % "Game launch command written to INI:`n" runCommand
    }
return

ClearSearch:
    ; Clear search field and results
    GuiControl,, SearchTerm
    LV_Delete()
    ClearImagePreview()

    ; Clear stored paths
    Loop, 50 {
        EbootPaths%A_Index% := ""
        IconPaths%A_Index% := ""
        PicPaths%A_Index% := ""
    }
return

; Double-click on ListView item to launch
ResultsListDoubleClick:
    Gosub, LaunchGame
return

; Helper function for joining array elements
Join(sep, ByRef arr) {
    out := ""
    for index, val in arr
        out .= (index > 1 ? sep : "") . val
    return out
}

GuiClose:
ExitApp
