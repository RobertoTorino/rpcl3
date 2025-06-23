#SingleInstance Force
#NoEnv
#Include %A_ScriptDir%\SQLiteDB.ahk


; Open DB
db := new SQLiteDB()
if !db.OpenDB(A_ScriptDir . "\games.db") {
    err := db.ErrorMsg
    MsgBox, 16, DB Error, Failed to open DB.`n%err%
    ExitApp
}

; Create GUI
Gui, Add, Text,, Search Games:
Gui, Add, Edit, vSearchInput w300
Gui, Add, Button, gDoSearch Default, Search
Gui, Add, ListBox, vResultList w400 h200
Gui, Show, w420 h280, Game Search
return

DoSearch:
Gui, Submit, NoHide
searchText := SearchInput

; Clear previous results
GuiControl,, ResultList

if (searchText = "") {
    return
}

; Escape single quotes for SQL query safety
escapedSearch := StrReplace(searchText, "'", "''")
sql := "SELECT GameId, GameTitle FROM games WHERE GameTitle LIKE '%" . escapedSearch . "%' ORDER BY GameTitle LIMIT 50"

if !db.GetTable(sql, result) {
    MsgBox, 16, Query Error, % "Query failed:`n" . db.ErrorMsg
    return
}

output := ""
Loop, % result.RowCount {
    row := ""
    if result.GetRow(A_Index, row)
        output .= row[1] " - " row[2] "`n"
}

GuiControl,, ResultList, %output%
return

GuiClose:
ExitApp
