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

; Quick access buttons section
Gui, Add, GroupBox, x10 y10 w380 h60, Quick Access
Gui, Add, Button, gShowAll x20 y30 w60 h20, Show All
Gui, Add, Button, gShowFavorites x85 y30 w60 h20, Favorites
Gui, Add, Button, gShowPlayed x150 y30 w50 h20, Played
Gui, Add, Button, gShowPSN x205 y30 w40 h20, PSN
Gui, Add, Button, gShowArcade x250 y30 w50 h20, Arcade

; Search section
Gui, Add, GroupBox, x10 y80 w380 h60, Search
Gui, Add, Text, x20 y100, Game title or ID:
Gui, Add, Edit, vSearchTerm x120 y97 w180 h20
Gui, Add, Button, gSearch x310 y97 w70 h23, Search

; Results section - ListView with favorite star column
Gui, Add, GroupBox, x10 y150 w380 h220, Results
Gui, Add, ListView, vResultsList x20 y170 w360 h170 Grid -Multi AltSubmit gListViewClick, ★|Game ID|Title
LV_ModifyCol(1, 25)  ; Star column
LV_ModifyCol(2, 80)  ; Game ID
LV_ModifyCol(3, 255) ; Title

; Image preview section
Gui, Add, GroupBox, x10 y380 w380 h100, Game Preview
Gui, Add, Picture, vGameIcon x20 y400 w64 h64 gShowLargeImage, ; Small icon preview
Gui, Add, Text, vImageStatus x95 y400, Select a game to see its icon

; Action buttons
Gui, Add, Button, gToggleFavorite x95 y430 w90 h25, Toggle Favorite
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

    ; Build WHERE clause for search
    whereClause := "WHERE (GameTitle LIKE '%" . StrReplace(searchTerm, "'", "''") . "%' OR GameId LIKE '%" . StrReplace(searchTerm, "'", "''") . "%')"

    ; Execute query with Favorite column
    sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1, Favorite FROM games " . whereClause . " ORDER BY GameTitle LIMIT 50"

    if !db.GetTable(sql, result) {
        MsgBox, 16, Query Error, % "Query failed:`n" . db.ErrorMsg
        return
    }

    PopulateResults(result)
return

ShowAll:
    ; Show all games
    sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1, Favorite FROM games ORDER BY GameTitle LIMIT 50"

    if !db.GetTable(sql, result) {
        MsgBox, 16, Query Error, % "Query failed:`n" . db.ErrorMsg
        return
    }

    PopulateResults(result)
return

ShowFavorites:
    ; Show only favorite games
    sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1, Favorite FROM games WHERE Favorite = 1 ORDER BY GameTitle LIMIT 50"

    if !db.GetTable(sql, result) {
        MsgBox, 16, Query Error, % "Query failed:`n" . db.ErrorMsg
        return
    }

    PopulateResults(result)
return

ShowPlayed:
    ; Show only played games
    sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1, Favorite FROM games WHERE Played = 1 ORDER BY GameTitle LIMIT 50"

    if !db.GetTable(sql, result) {
        MsgBox, 16, Query Error, % "Query failed:`n" . db.ErrorMsg
        return
    }

    PopulateResults(result)
return

ShowPSN:
    ; Show only PSN games
    sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1, Favorite FROM games WHERE PSN = 1 ORDER BY GameTitle LIMIT 50"

    if !db.GetTable(sql, result) {
        MsgBox, 16, Query Error, % "Query failed:`n" . db.ErrorMsg
        return
    }

    PopulateResults(result)
return

ShowArcade:
    ; Show only Arcade games
    sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1, Favorite FROM games WHERE ArcadeGame = 1 ORDER BY GameTitle LIMIT 50"

    if !db.GetTable(sql, result) {
        MsgBox, 16, Query Error, % "Query failed:`n" . db.ErrorMsg
        return
    }

    PopulateResults(result)
return

PopulateResults(result) {
    ; Clear and populate ListView with favorite stars
    LV_Delete()

    if (result.RowCount = 0) {
        LV_Add("", "", "No results found", "")
        ClearImagePreview()
        return
    }

    ; Add results to ListView and store paths
    Loop, % result.RowCount {
        row := ""
        if result.GetRow(A_Index, row) {
            ; Store all the paths and info in global arrays for later use
            GameIds%A_Index% := row[1]
            GameTitles%A_Index% := row[2]
            EbootPaths%A_Index% := row[3]
            IconPaths%A_Index% := row[4]
            PicPaths%A_Index% := row[5]
            FavoriteStatus%A_Index% := row[6]

            ; Add row with star if favorite
            favoriteIcon := (row[6] = 1) ? "★" : ""
            LV_Add("", favoriteIcon, row[1], row[2])
        }
    }

    ; Auto-resize columns
    LV_ModifyCol(1, 25)   ; Keep star column small
    LV_ModifyCol(2, "AutoHdr")
    LV_ModifyCol(3, "AutoHdr")

    ; Clear image preview
    ClearImagePreview()
}

ListViewClick:
    ; Handle ListView selection change
    selectedRow := LV_GetNext()
    if (selectedRow > 0) {
        ShowGameIcon(selectedRow)
        UpdateFavoriteButton(selectedRow)
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
        CurrentSelectedRow := rowIndex
    }
}

UpdateFavoriteButton(rowIndex) {
    ; Update button text based on current favorite status
    isFavorite := FavoriteStatus%rowIndex%
    if (isFavorite = 1) {
        GuiControl,, Button9, Remove Favorite  ; Button9 is the Toggle Favorite button
    } else {
        GuiControl,, Button9, Add Favorite
    }
}

ToggleFavorite:
    ; Get selected row
    selectedRow := LV_GetNext()
    if (!selectedRow) {
        MsgBox, 48, No Selection, Please select a game from the list.
        return
    }

    ; Get game info
    gameId := GameIds%selectedRow%
    currentFavorite := FavoriteStatus%selectedRow%

    ; Toggle favorite status
    newFavorite := (currentFavorite = 1) ? 0 : 1

    ; Update database
    sql := "UPDATE games SET Favorite = " . newFavorite . " WHERE GameId = '" . StrReplace(gameId, "'", "''") . "'"

    if !db.Exec(sql) {
        MsgBox, 16, Database Error, Failed to update favorite status
        return
    }

    ; Update local storage
    FavoriteStatus%selectedRow% := newFavorite

    ; Update ListView star
    favoriteIcon := (newFavorite = 1) ? "★" : ""
    LV_Modify(selectedRow, Col1, favoriteIcon)

    ; Update button text
    UpdateFavoriteButton(selectedRow)

    ; Show confirmation
    statusText := (newFavorite = 1) ? "added to" : "removed from"
    gameTitle := GameTitles%selectedRow%
    MsgBox, 64, Success, %gameTitle% has been %statusText% favorites!
return

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
    GuiControl,, Button9, Toggle Favorite  ; Reset button text
    CurrentSelectedRow := 0
}

LaunchGame:
    ; Get selected row
    selectedRow := LV_GetNext()
    if (!selectedRow) {
        MsgBox, 48, No Selection, Please select a game from the list.
        return
    }

    ; Get game info from stored arrays
    gameId := GameIds%selectedRow%
    gameTitle := GameTitles%selectedRow%

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
        MsgBox, 64, Success, Game launch command written to INI:`n%runCommand%
    }
return

ClearSearch:
    ; Clear search field and results
    GuiControl,, SearchTerm
    LV_Delete()
    ClearImagePreview()

    ; Clear stored paths
    Loop, 50 {
        GameIds%A_Index% := ""
        GameTitles%A_Index% := ""
        EbootPaths%A_Index% := ""
        IconPaths%A_Index% := ""
        PicPaths%A_Index% := ""
        FavoriteStatus%A_Index% := ""
    }
return

; Double-click on ListView item to launch
ResultsListDoubleClick:
    Gosub, LaunchGame
return

GuiClose:
ExitApp
