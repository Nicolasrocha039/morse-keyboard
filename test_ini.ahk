try {
    iniPath := A_ScriptDir . "\morse_map.ini"
    mapStr := IniRead(iniPath, "MorseMap")
    FileAppend(mapStr, "dump_ini.txt", "UTF-8")
} catch as e {
    FileAppend("Error", "dump_ini.txt", "UTF-8")
}
