#Requires AutoHotkey v2.0
#Include morse_config.ahk
LoadConfig()
try {
    FileAppend(morseMap.Count, A_ScriptDir . "\test_map.txt")
} catch as e {
    FileAppend("Error: " . e.Message, A_ScriptDir . "\test_map.txt")
}
