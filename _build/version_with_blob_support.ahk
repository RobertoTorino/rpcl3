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
Gui, Add, Text, vImageSource x95 y415, ; Shows if from file or database

; Action buttons
Gui, Add, Button, gToggleFavorite x95 y450 w90 h25, Toggle Favorite
Gui, Add, Button, gLaunchGame x200 y430 w80 h30, Launch
Gui, Add, Button, gClearSearch x290 y430 w80 h30, Clear

Gui, Show, w400 h510, Game Search Launcher
return

Search:
    Gui, Submit, NoHide

    searchTerm := Trim(SearchTerm)
    if (searchTerm = "") {
        MsgBox, 48, Input Required, Please enter a search term.
        return
    }

    whereClause := "WHERE (GameTitle LIKE '%" . StrReplace(searchTerm, "'", "''") . "%' OR GameId LIKE '%" . StrReplace(searchTerm, "'", "''") . "%')"

    ; Query now includes IconBlob
    sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1, Favorite, IconBlob FROM games " . whereClause . " ORDER BY GameTitle LIMIT 50"

    if !db.GetTable(sql, result) {
        MsgBox, 16, Query Error, Query failed
        return
    }

    PopulateResults(result)
return

ShowAll:
    sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1, Favorite, IconBlob FROM games ORDER BY GameTitle LIMIT 50"
    if !db.GetTable(sql, result) {
        MsgBox, 16, Query Error, Query failed
        return
    }
    PopulateResults(result)
return

ShowFavorites:
    sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1, Favorite, IconBlob FROM games WHERE Favorite = 1 ORDER BY GameTitle LIMIT 50"
    if !db.GetTable(sql, result) {
        MsgBox, 16, Query Error, Query failed
        return
    }
    PopulateResults(result)
return

ShowPlayed:
    sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1, Favorite, IconBlob FROM games WHERE Played = 1 ORDER BY GameTitle LIMIT 50"
    if !db.GetTable(sql, result) {
        MsgBox, 16, Query Error, Query failed
        return
    }
    PopulateResults(result)
return

ShowPSN:
    sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1, Favorite, IconBlob FROM games WHERE PSN = 1 ORDER BY GameTitle LIMIT 50"
    if !db.GetTable(sql, result) {
        MsgBox, 16, Query Error, Query failed
        return
    }
    PopulateResults(result)
return

ShowArcade:
    sql := "SELECT GameId, GameTitle, Eboot, Icon0, Pic1, Favorite, IconBlob FROM games WHERE ArcadeGame = 1 ORDER BY GameTitle LIMIT 50"
    if !db.GetTable(sql, result) {
        MsgBox, 16, Query Error, Query failed
        return
    }
    PopulateResults(result)
return

PopulateResults(result) {
    LV_Delete()

    if (result.RowCount = 0) {
        LV_Add("", "", "No results found", "")
        ClearImagePreview()
        return
    }

    Loop, % result.RowCount {
        row := ""
        if result.GetRow(A_Index, row) {
            GameIds%A_Index% := row[1]
            GameTitles%A_Index% := row[2]
            EbootPaths%A_Index% := row[3]
            IconPaths%A_Index% := row[4]      ; File path (fallback)
            PicPaths%A_Index% := row[5]
            FavoriteStatus%A_Index% := row[6]
            IconBlobs%A_Index% := row[7]      ; BLOB data

            favoriteIcon := (row[6] = 1) ? "★" : ""
            LV_Add("", favoriteIcon, row[1], row[2])
        }
    }

    LV_ModifyCol(1, 25)
    LV_ModifyCol(2, "AutoHdr")
    LV_ModifyCol(3, "AutoHdr")

    ClearImagePreview()
}

ListViewClick:
    selectedRow := LV_GetNext()
    if (selectedRow > 0) {
        ShowGameIcon(selectedRow)
        UpdateFavoriteButton(selectedRow)
    } else {
        ClearImagePreview()
    }
return

ShowGameIcon(rowIndex) {
    ; Try to use BLOB data first, fallback to file
    iconBlob := IconBlobs%rowIndex%
    iconPath := IconPaths%rowIndex%

    imageLoaded := false
    imageSource := ""

    ; Try BLOB first
    if (iconBlob != "" && IsObject(iconBlob)) {
        ; Create temporary file from BLOB
        tempFile := A_Temp . "\temp_icon_" . A_TickCount . ".png"
        file := FileOpen(tempFile, "w")
        if (file) {
            file.RawWrite(iconBlob.Blob, iconBlob.Size)
            file.Close()

            ; Load image from temp file
            GuiControl,, GameIcon, %tempFile%
            imageLoaded := true
            imageSource := "database"

            ; Schedule temp file cleanup
            SetTimer, CleanupTempIcon, -1000
        }
    }

    ; Fallback to file path
    if (!imageLoaded && iconPath != "" && FileExist(iconPath)) {
        GuiControl,, GameIcon, %iconPath%
        imageLoaded := true
        imageSource := "file"
    }

    ; Update status
    if (imageLoaded) {
        GuiControl,, ImageStatus, Click icon for larger view
        GuiControl,, ImageSource, Source: %imageSource%
        CurrentSelectedRow := rowIndex
    } else {
        GuiControl,, GameIcon,
        GuiControl,, ImageStatus, No icon available
        GuiControl,, ImageSource,
        CurrentSelectedRow := rowIndex
    }
return

CleanupTempIcon:
    ; Clean up temporary files
    Loop, Files, %A_Temp%\temp_icon_*.png
    {
        FileDelete, %A_LoopFileFullPath%
    }
return

; ... rest of your existing functions remain the same ...

ToggleFavorite:
    selectedRow := LV_GetNext()
    if (!selectedRow) {
        MsgBox, 48, No Selection, Please select a game from the list.
        return
    }

    gameId := GameIds%selectedRow%
    currentFavorite := FavoriteStatus%selectedRow%
    newFavorite := (currentFavorite = 1) ? 0 : 1

    sql := "UPDATE games SET Favorite = " . newFavorite . " WHERE GameId = '" . StrReplace(gameId, "'", "''") . "'"

    if !db.Exec(sql) {
        MsgBox, 16, Database Error, Failed to update favorite status
        return
    }

    FavoriteStatus%selectedRow% := newFavorite
    favoriteIcon := (newFavorite = 1) ? "★" : ""
    LV_Modify(selectedRow, Col1, favoriteIcon)
    UpdateFavoriteButton(selectedRow)

    statusText := (newFavorite = 1) ? "added to" : "removed from"
    gameTitle := GameTitles%selectedRow%
    MsgBox, 64, Success, %gameTitle% has been %statusText% favorites!
return

UpdateFavoriteButton(rowIndex) {
    isFavorite := FavoriteStatus%rowIndex%
    if (isFavorite = 1) {
        GuiControl,, Button9, Remove Favorite
    } else {
        GuiControl,, Button9, Add Favorite
    }
}

; ... rest of existing functions ...

GuiClose:
ExitApp
