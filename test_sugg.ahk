
#Include morse_config.ahk
#Include morse_core.ahk

LoadConfig()
suggestion := GetAutocompleteSuggestion("digitacao")
FileAppend(suggestion, "test_sugg_out.txt", "UTF-8")
ExitApp

