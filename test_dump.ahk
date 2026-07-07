#Requires AutoHotkey v2.0
morseMap := Map()
try {
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
    FileAppend("Map count: " . morseMap.Count . "`n", "dump.txt", "UTF-8")
    for k, v in morseMap {
        FileAppend(k . " -> " . v . "`n", "dump.txt", "UTF-8")
        break
    }
} catch as e {
    FileAppend("Error: " . e.Message, "dump.txt", "UTF-8")
}
