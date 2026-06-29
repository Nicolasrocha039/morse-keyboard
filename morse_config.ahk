#Requires AutoHotkey v2.0

; Variáveis globais de interface
global osdGeral1 := ""
global osdGeral2 := ""
global osdSyllables := ""
global osdTriples := ""

; Dicionário de atalhos
global morseMap := Map()

LoadConfig() {
    global osdGeral1, osdGeral2, osdSyllables, osdTriples, morseMap

    ; Carregar os textos da interface
    try osdGeral1 := FileRead(A_ScriptDir . "\osd_geral_col1.txt", "UTF-8")
    try osdGeral2 := FileRead(A_ScriptDir . "\osd_geral_col2.txt", "UTF-8")
    try osdSyllables := FileRead(A_ScriptDir . "\osd_syllables.txt", "UTF-8")
    try osdTriples := FileRead(A_ScriptDir . "\osd_triples.txt", "UTF-8")

    ; Carregar dicionário a partir do arquivo INI
    try {
        iniPath := A_ScriptDir . "\morse_map.ini"
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
}

; Executar no momento da inclusão
LoadConfig()
