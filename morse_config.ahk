#Requires AutoHotkey v2.0

; Variáveis globais de interface
global osdGeral1 := ""
global osdGeral2 := ""
global osdAdb1 := ""
global osdAdb2 := ""
global osdMKey1 := ""
global osdMKey2 := ""
global osdMacro1 := ""
global osdMacro2 := ""
global osdFKey1 := ""
global osdFKey2 := ""
global osdSpotify1 := ""
global osdSpotify2 := ""
global osdTeams1 := ""
global osdTeams2 := ""
global osdSyllables := ""
global osdTriples := ""

; Dicionário de atalhos e dicionário de palavras
global morseMap := Map()
global dictArray := []

global traditionalMode := false

LoadConfig(useTraditionalMap := false) {
    global osdGeral1, osdGeral2, osdAdb1, osdAdb2, osdMKey1, osdMKey2, osdMacro1, osdMacro2, osdFKey1, osdFKey2, osdSpotify1, osdSpotify2, osdTeams1, osdTeams2, osdSyllables, osdTriples, morseMap, dictArray, traditionalMode
    traditionalMode := useTraditionalMap

    ; Carregar os textos da interface
    try osdGeral1 := FileRead(A_ScriptDir . "\osd_geral_col1.txt", "UTF-8")
    try osdGeral2 := FileRead(A_ScriptDir . "\osd_geral_col2.txt", "UTF-8")
    try osdAdb1 := FileRead(A_ScriptDir . "\osd_adb_col1.txt", "UTF-8")
    try osdAdb2 := FileRead(A_ScriptDir . "\osd_adb_col2.txt", "UTF-8")
    try osdMKey1 := FileRead(A_ScriptDir . "\osd_mkey_col1.txt", "UTF-8")
    try osdMKey2 := FileRead(A_ScriptDir . "\osd_mkey_col2.txt", "UTF-8")
    try osdMacro1 := FileRead(A_ScriptDir . "\osd_macro_col1.txt", "UTF-8")
    try osdMacro2 := FileRead(A_ScriptDir . "\osd_macro_col2.txt", "UTF-8")
    try osdFKey1 := FileRead(A_ScriptDir . "\osd_fkey_col1.txt", "UTF-8")
    try osdFKey2 := FileRead(A_ScriptDir . "\osd_fkey_col2.txt", "UTF-8")
    try osdSpotify1 := FileRead(A_ScriptDir . "\osd_spotify_col1.txt", "UTF-8")
    try osdSpotify2 := FileRead(A_ScriptDir . "\osd_spotify_col2.txt", "UTF-8")
    try osdTeams1 := FileRead(A_ScriptDir . "\osd_teams_col1.txt", "UTF-8")
    try osdTeams2 := FileRead(A_ScriptDir . "\osd_teams_col2.txt", "UTF-8")
    try osdSyllables := FileRead(A_ScriptDir . "\osd_syllables.txt", "UTF-8")
    try osdTriples := FileRead(A_ScriptDir . "\osd_triples.txt", "UTF-8")

    ; Carregar dicionário a partir do arquivo INI
    try {
        iniPath := A_ScriptDir . (useTraditionalMap ? "\morse_map_traditional.ini" : "\morse_map.ini")
        mapStr := IniRead(iniPath, "MorseMap")
        Loop Parse, mapStr, "`n", "`r"
        {
            parts := StrSplit(A_LoopField, "=")
            if (parts.Length >= 2) { ; >= 2 para ignorar caso o valor tenha um = no meio
                ; O AutoHotkey v2 StrSplit divide tudo. Vamos juntar o resto caso a string de valor contenha '='
                key := parts[1]
                parts.RemoveAt(1)
                val := ""
                for index, part in parts {
                    val .= part . (index < parts.Length ? "=" : "")
                }
                morseMap[key] := val
            }
        }
    } catch as err {
        MsgBox("Erro ao carregar morse_map.ini: " . err.Message)
    }

    ; Carregar dicionário de palavras na memória RAM
    try {
        dictContent := FileRead(A_ScriptDir . "\dict.ini", "UTF-8")
        Loop Parse, dictContent, "`n", "`r"
        {
            if (A_LoopField != "" && SubStr(A_LoopField, 1, 1) != "[") {
                parts := StrSplit(A_LoopField, "=")
                if (parts.Length >= 2 && parts[2] != "") {
                    dictArray.Push({key: parts[1], word: parts[2]})
                } else if (parts.Length >= 1 && parts[1] != "") {
                    dictArray.Push({key: parts[1], word: parts[1]})
                }
            }
        }
    } catch as err {
        MsgBox("Erro ao carregar dict.ini: " . err.Message)
    }
}

; Executar no momento da inclusão
LoadConfig()

