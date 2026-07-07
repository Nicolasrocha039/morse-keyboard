try {
    morseMap := Map()
    iniPath := A_ScriptDir . "\morse_map.ini"
    mapStr := IniRead(iniPath, "MorseMap")
    Loop Parse, mapStr, "`n", "`r"
    {
        parts := StrSplit(A_LoopField, "=")
        if (parts.Length >= 2) {
            key := parts[1]
            parts.RemoveAt(1)
            val := ""
            for index, part in parts {
                val .= part . (index < parts.Length ? "=" : "")
            }
            morseMap[key] := val
        }
    }
    FileAppend(morseMap["RAQQ"], "dump_ahk.txt", "UTF-8")
} catch as e {
    FileAppend("Error", "dump_ahk.txt", "UTF-8")
}
