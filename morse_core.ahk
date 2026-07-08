#Requires AutoHotkey v2.0

SendStateToPython() {
    global wordBuffer, visualBuffer, currentSequence, morseActive

    ; Tratar escapes JSON simples
    escapedWord := StrReplace(wordBuffer, '\', '\\')
    escapedWord := StrReplace(escapedWord, '"', '\"')
    escapedWord := StrReplace(escapedWord, '`n', '\n')
    escapedWord := StrReplace(escapedWord, '`r', '\r')

    escapedVisual := StrReplace(visualBuffer, '\', '\\')
    escapedVisual := StrReplace(escapedVisual, '"', '\"')
    escapedVisual := StrReplace(escapedVisual, '`n', '\n')
    escapedVisual := StrReplace(escapedVisual, '`r', '\r')

    suggestion := GetAutocompleteSuggestion(visualBuffer)
    escapedSuggestion := StrReplace(suggestion, '\', '\\')
    escapedSuggestion := StrReplace(escapedSuggestion, '"', '\"')

    jsonData := '{"word": "' . escapedWord . '", "visual": "' . escapedVisual . '", "seq": "' . currentSequence . '", "suggestion": "' . escapedSuggestion . '", "active": ' . (morseActive ? "true" : "false") . '}'

    try {
        http := ComObject("Msxml2.XMLHTTP")
        http.open("POST", "http://127.0.0.1:8766/state", true)
        http.setRequestHeader("Content-Type", "application/json")
        http.send(jsonData)
    }
}

FormatSequence(seq) {
    result := ""
    Loop Parse, seq {
        if A_Index > 1
            result .= " · "
        result .= A_LoopField
    }
    return result
}

RemoveAccents(str) {
    str := StrReplace(str, "á", "a")
    str := StrReplace(str, "à", "a")
    str := StrReplace(str, "ã", "a")
    str := StrReplace(str, "â", "a")
    str := StrReplace(str, "é", "e")
    str := StrReplace(str, "ê", "e")
    str := StrReplace(str, "í", "i")
    str := StrReplace(str, "ó", "o")
    str := StrReplace(str, "õ", "o")
    str := StrReplace(str, "ô", "o")
    str := StrReplace(str, "ú", "u")
    str := StrReplace(str, "ç", "c")
    return str
}

GetAutocompleteSuggestion(visualWord) {
    global wordBuffer
    if (visualWord = "" || StrLen(visualWord) < 2)
        return ""

    isFirstUpper := IsUpper(SubStr(visualWord, 1, 1))

    escapedWordBuffer := StrReplace(wordBuffer, '\', '\\')
    escapedWordBuffer := StrReplace(escapedWordBuffer, '"', '\"')
    escapedWordBuffer := StrReplace(escapedWordBuffer, '`n', '\n')
    escapedWordBuffer := StrReplace(escapedWordBuffer, '`r', '\r')

    escapedVisual := StrReplace(visualWord, '\', '\\')
    escapedVisual := StrReplace(escapedVisual, '"', '\"')

    jsonData := '{"wordBuffer": "' . escapedWordBuffer . '", "visualBuffer": "' . escapedVisual . '"}'

    try {
        http := ComObject("Msxml2.XMLHTTP")
        http.open("POST", "http://127.0.0.1:8766/suggest", false) ; síncrono
        http.setRequestHeader("Content-Type", "application/json")
        http.send(jsonData)

        response := http.responseText
        if RegExMatch(response, '"suggestion"\s*:\s*"([^"]*)"', &match) {
            suggestion := match[1]
            if (suggestion != "" && isFirstUpper) {
                suggestion := StrUpper(SubStr(suggestion, 1, 1)) . SubStr(suggestion, 2)
            }
            return suggestion
        }
    }
    return ""
}

LearnWordContext() {
    global wordBuffer
    escapedWordBuffer := StrReplace(wordBuffer, '\', '\\')
    escapedWordBuffer := StrReplace(escapedWordBuffer, '"', '\"')
    escapedWordBuffer := StrReplace(escapedWordBuffer, '`n', '\n')
    escapedWordBuffer := StrReplace(escapedWordBuffer, '`r', '\r')

    jsonData := '{"wordBuffer": "' . escapedWordBuffer . '"}'
    try {
        http := ComObject("Msxml2.XMLHTTP")
        http.open("POST", "http://127.0.0.1:8766/learn", true) ; assíncrono
        http.setRequestHeader("Content-Type", "application/json")
        http.send(jsonData)
    }
}

GetPossibleMatches(seq) {
    global morseMap
    matches := ""
    count := 0

    ; Verificar match exato
    if morseMap.Has(seq) {
        val := morseMap[seq]
        matches .= "→ " . FormatOutput(val)
    }

    ; Verificar possíveis extensões
    for key, val in morseMap {
        if StrLen(key) > StrLen(seq) && SubStr(key, 1, StrLen(seq)) = seq {
            count++
        }
    }

    if count > 0 {
        if matches != ""
            matches .= " | "
        matches .= "+" . count . " opções"
    }

    return matches != "" ? matches : "sem match"
}

FormatOutput(val) {
    if SubStr(val, 1, 1) = "{" {
        inner := SubStr(val, 2, StrLen(val) - 2)
        return "[" . inner . "]"
    }
    if SubStr(val, 1, 1) = "^" {
        return "Ctrl+" . SubStr(val, 2)
    }
    if SubStr(val, 1, 2) = "+{" {
        inner := SubStr(val, 3, StrLen(val) - 3)
        return "Shift+[" . inner . "]"
    }
    return val
}

UpdateVisualBufferFromWordBuffer() {
    global wordBuffer, visualBuffer
    if wordBuffer = "" {
        visualBuffer := ""
        return
    }
    lastSpaceIdx := InStr(wordBuffer, " ", , -1)
    if lastSpaceIdx = 0 {
        visualBuffer := wordBuffer
    } else {
        visualBuffer := SubStr(wordBuffer, lastSpaceIdx + 1)
    }
}

LogBuffers(action) {
    global wordBuffer, visualBuffer, currentSequence
    try {
        FileAppend("[" . A_Now . "] Action: " . action . " | seq: '" . currentSequence . "' | word: '" . wordBuffer . "' | vis: '" . visualBuffer . "'`n", "debug_buffer.txt", "UTF-8")
    }
}

SendToSystem(output) {
    global adbMode
    if output = "{ToggleADB}" {
        adbMode := !adbMode
        if adbMode
            ToolTip("ADB Mode: ON`nKeys will be sent to Android", A_ScreenWidth / 2 - 150, A_ScreenHeight / 2)
        else
            ToolTip("ADB Mode: OFF`nKeys will be sent to Windows", A_ScreenWidth / 2 - 150, A_ScreenHeight / 2)
        SetTimer(() => ToolTip(), -2500)
        LogBuffers("Toggle ADB Mode: " . (adbMode ? "ON" : "OFF"))
        return
    }
    if output = "{Reload}" {
        Reload()
        return
    }

    if output = "{ToggleLButton}" {
        global lbuttonLocked
        lbuttonLocked := !lbuttonLocked
        ToolTip("Mouse Esq " . (lbuttonLocked ? "BLOQUEADO (Limpa buffers)" : "LIBERADO (Clique normal)"), A_ScreenWidth / 2 - 150, A_ScreenHeight / 2)
        SetTimer(() => ToolTip(), -2500)
        LogBuffers("Toggle LButton Locked: " . (lbuttonLocked ? "ON" : "OFF"))
        return
    }

    if output = "{ToggleTraditionalMode}" {
        global traditionalMode
        LoadConfig(!traditionalMode)
        ToolTip("Layout Tradicional " . (traditionalMode ? "ATIVADO" : "DESATIVADO"), A_ScreenWidth / 2 - 150, A_ScreenHeight / 2)
        SetTimer(() => ToolTip(), -2500)
        LogBuffers("Toggle Traditional Mode: " . (traditionalMode ? "ON" : "OFF"))
        UpdateOSD()
        return
    }

    if adbMode {
        adbPath := '"' . A_ScriptDir . '\platform-tools\adb.exe"'

        if output = "{Space}" || output = " " {
            RunWait(adbPath . " shell input keyevent 62", , "Hide")
        } else if output = "{Enter}" || output = "`n" {
            RunWait(adbPath . " shell input keyevent 66", , "Hide")
        } else if output = "{Backspace}" {
            RunWait(adbPath . " shell input keyevent 67", , "Hide")
        } else if output = "^{Backspace}" {
            ; Enviar vários backspaces para emular deletar palavra
            Loop 10 {
                RunWait(adbPath . " shell input keyevent 67", , "Hide")
            }
        } else if output = "{Escape}" {
            RunWait(adbPath . " shell input keyevent 4", , "Hide") ; BACK
        } else if output = "{Home}" {
            RunWait(adbPath . " shell input keyevent 3", , "Hide") ; HOME
        } else if output = "{Tab}" {
            RunWait(adbPath . " shell input keyevent 187", , "Hide") ; APP SWITCH/RECENTS
        } else if output = "{Up}" {
            RunWait(adbPath . " shell input keyevent 19", , "Hide") ; DPAD UP
        } else if output = "{Down}" {
            RunWait(adbPath . " shell input keyevent 20", , "Hide") ; DPAD DOWN
        } else if output = "{Left}" {
            RunWait(adbPath . " shell input keyevent 21", , "Hide") ; DPAD LEFT
        } else if output = "{Right}" {
            RunWait(adbPath . " shell input keyevent 22", , "Hide") ; DPAD RIGHT
        } else if output = "{AndroidPower}" {
            RunWait(adbPath . " shell input keyevent 26", , "Hide") ; POWER/WAKE
        } else if output = "{ToggleBluetooth}" {
            RunWait(adbPath . " shell `"if [ \`"$(settings get global bluetooth_on)\`" = \`"1\`" ]; then svc bluetooth disable; cmd bluetooth_manager disable; else svc bluetooth enable; cmd bluetooth_manager enable; fi`"", , "Hide")
            ToolTip("Comando de Bluetooth enviado via ADB", A_ScreenWidth / 2 - 150, A_ScreenHeight / 2)
            SetTimer(() => ToolTip(), -2500)
        } else if output = "{ConnectBTDevice}" {
            RunWait(adbPath . " shell am start -a android.settings.BLUETOOTH_SETTINGS", , "Hide")
            Sleep(1500)
            ; Quantidade de setas para baixo depende da posição do dispositivo na lista
            Loop 2 {
                RunWait(adbPath . " shell input keyevent 20", , "Hide") ; DOWN
                Sleep(300)
            }
            RunWait(adbPath . " shell input keyevent 66", , "Hide") ; ENTER
            ToolTip("Automação de conexão Bluetooth executada", A_ScreenWidth / 2 - 150, A_ScreenHeight / 2)
            SetTimer(() => ToolTip(), -2500)
        } else if output = "{WheelUp}" {
            ; Swipe down to scroll up
            RunWait(adbPath . " shell input swipe 500 600 500 1600 150", , "Hide")
        } else if output = "{WheelDown}" {
            ; Swipe up to scroll down
            RunWait(adbPath . " shell input swipe 500 1600 500 600 150", , "Hide")
        } else if output = "{WheelLeft}" {
            ; Swipe right to scroll left (content moves right)
            RunWait(adbPath . " shell input swipe 800 1400 200 1400 150", , "Hide")
        } else if output = "{WheelRight}" {
            ; Swipe left to scroll right (content moves left)
            RunWait(adbPath . " shell input swipe 200 1400 800 1400 150", , "Hide")
        } else if output = "{LButton}" || output = "{RButton}" || output = "{MButton}" || output = "{WheelUp}" || output = "{WheelDown}" || output = "{WheelLeft}" || output = "{WheelRight}" {
            Send(output)
        } else if RegExMatch(output, "i)^\^([a-z])$", &match) {
            ; Atalhos de texto: Ctrl+C, Ctrl+X, Ctrl+V, Ctrl+Z, Ctrl+A
            char := StrLower(match[1])
            if char == "c"
                RunWait(adbPath . " shell input keyevent 278", , "Hide") ; COPY
            else if char == "x"
                RunWait(adbPath . " shell input keyevent 277", , "Hide") ; CUT
            else if char == "v"
                RunWait(adbPath . " shell input keyevent 279", , "Hide") ; PASTE
            else if char == "z"
                RunWait(adbPath . " shell input keyevent 281", , "Hide") ; UNDO
            else if char == "a"
                RunWait(adbPath . " shell input keyevent 286", , "Hide") ; SELECT ALL
            else {
                escapedOutput := StrReplace(output, "'", "'\''")
                adbCmd := adbPath . ' shell am broadcast -a ADB_INPUT_TEXT --es msg ' . "'" . escapedOutput . "'"
                RunWait(adbCmd, , "Hide")
            }
        } else {
            ; Usando o ADBKeyBoard para suportar acentos e caracteres especiais nativamente
            escapedOutput := StrReplace(output, "'", "'\''")

            ; Envia os caracteres usando o Intent de broadcast do ADBKeyBoard
            adbCmd := adbPath . ' shell am broadcast -a ADB_INPUT_TEXT --es msg ' . "'" . escapedOutput . "'"
            RunWait(adbCmd, , "Hide")
        }
    } else {
        if output = " "
            Send("{Blind}{Space}")
        else if output = "{AndroidPower}"
            return
        else if output = "^" || output = "~" || output = "´" || output = "``" || output = "!" || output = "+" || output = "#"
            Send("{Blind}{" . output . "}")
        else if SubStr(output, 1, 1) = "{" || SubStr(output, 1, 1) = "^" || SubStr(output, 1, 1) = "!" || SubStr(output, 1, 1) = "#" || SubStr(output, 1, 1) = "+"
            Send("{Blind}" . output)
        else
            Send("{Blind}{Raw}" . output)
    }
}

ProcessSequence() {
    global currentSequence, morseMap, wordBuffer, visualBuffer, adbMode

    if currentSequence = ""
        return

    seq := currentSequence
    currentSequence := ""

    LogBuffers("ProcessSequence Start (seq: " . seq . ")")

    if morseMap.Has(seq) {
        output := morseMap[seq]

        if output = "{RepeatLast}" {
            global lastSentCommand
            if lastSentCommand != "" {
                output := lastSentCommand
            } else {
                return ; Nada para repetir
            }
        } else {
            global lastSentCommand
            lastSentCommand := output
        }

        ; === DEAD KEYS: Modificadores e Acentos acumulam separadamente ===
        global pendingModifiers, pendingAccent, pendingSpecial
        if !IsSet(pendingModifiers)
            pendingModifiers := ""
        if !IsSet(pendingAccent)
            pendingAccent := ""
        if !IsSet(pendingSpecial)
            pendingSpecial := ""

        ; Modificadores sticky → acumulam prefixo AHK (^, !, +, #)
        if output = "{Ctrl}" {
            if InStr(pendingModifiers, "^")
                pendingModifiers := StrReplace(pendingModifiers, "^", "")
            else
                pendingModifiers .= "^"
            ToolTip("Modificadores: " . (pendingModifiers != "" ? pendingModifiers : "(nenhum)"), A_ScreenWidth / 2 - 80, A_ScreenHeight / 2)
            SetTimer(() => ToolTip(), -1500)
            LogBuffers("Modifier Toggle Ctrl → pendingModifiers: " . pendingModifiers)
            UpdateOSD()
            return
        }
        if output = "{Shift}" {
            if InStr(pendingModifiers, "+")
                pendingModifiers := StrReplace(pendingModifiers, "+", "")
            else
                pendingModifiers .= "+"
            ToolTip("Modificadores: " . (pendingModifiers != "" ? pendingModifiers : "(nenhum)"), A_ScreenWidth / 2 - 80, A_ScreenHeight / 2)
            SetTimer(() => ToolTip(), -1500)
            LogBuffers("Modifier Toggle Shift → pendingModifiers: " . pendingModifiers)
            UpdateOSD()
            return
        }
        if output = "{Alt}" {
            if InStr(pendingModifiers, "!")
                pendingModifiers := StrReplace(pendingModifiers, "!", "")
            else
                pendingModifiers .= "!"
            ToolTip("Modificadores: " . (pendingModifiers != "" ? pendingModifiers : "(nenhum)"), A_ScreenWidth / 2 - 80, A_ScreenHeight / 2)
            SetTimer(() => ToolTip(), -1500)
            LogBuffers("Modifier Toggle Alt → pendingModifiers: " . pendingModifiers)
            UpdateOSD()
            return
        }
        if output = "{LWin}" || output = "{RWin}" {
            if InStr(pendingModifiers, "#")
                pendingModifiers := StrReplace(pendingModifiers, "#", "")
            else
                pendingModifiers .= "#"
            ToolTip("Modificadores: " . (pendingModifiers != "" ? pendingModifiers : "(nenhum)"), A_ScreenWidth / 2 - 80, A_ScreenHeight / 2)
            SetTimer(() => ToolTip(), -1500)
            LogBuffers("Modifier Toggle Win → pendingModifiers: " . pendingModifiers)
            UpdateOSD()
            return
        }

        ; Acentos (dead keys) → acumulam no prefixo como caractere literal
        if output = "^" || output = "~" || output = "´" || output = "``" {
            pendingAccent := output
            ToolTip("Acento pendente: " . pendingAccent, A_ScreenWidth / 2 - 80, A_ScreenHeight / 2)
            SetTimer(() => ToolTip(), -1500)
            LogBuffers("Accent: " . pendingAccent)
            UpdateOSD()
            return
        }

        ; FKey / MKey → acumulam marcador especial no prefixo
        if output = "{FKey}" {
            pendingSpecial := "F:"
            ToolTip("Prefixo F-Key: aguardando número (1-9, 0=F10, a=F11, b=F12)", A_ScreenWidth / 2 - 180, A_ScreenHeight / 2)
            SetTimer(() => ToolTip(), -3000)
            LogBuffers("FKey Prefix: " . pendingSpecial)
            UpdateOSD()
            return
        }
        if output = "{MKey}" {
            pendingSpecial := "M:"
            ToolTip("Media (Kumara): 1=PC 2=Search 3=Calc 4=Player 5=Prev 6=Next 7=Play 8=Stop 9=Mute 0=Vol- a=Vol+", A_ScreenWidth / 2 - 300, A_ScreenHeight / 2)
            SetTimer(() => ToolTip(), -3000)
            LogBuffers("MKey Prefix: " . pendingSpecial)
            UpdateOSD()
            return
        }
        if output = "{MacroKey}" {
            pendingSpecial := "X:"
            ToolTip("Prefixo Macro: 1=3dPrecifier 2=SemantiCron 3=Dork", A_ScreenWidth / 2 - 180, A_ScreenHeight / 2)
            SetTimer(() => ToolTip(), -3000)
            LogBuffers("MacroKey Prefix: " . pendingSpecial)
            UpdateOSD()
            return
        }

        ; === A partir daqui, é uma tecla final — montar o envio completo ===

        ; Resolver FKey / MKey se estão no pendingPrefix
        if pendingSpecial == "F:" {
            ; Mapear: 1-9→F1-F9, 0→F10, a→F11, b→F12
            fkeyMap := Map("1", "{F1}", "2", "{F2}", "3", "{F3}", "4", "{F4}", "5", "{F5}", "6", "{F6}", "7", "{F7}", "8", "{F8}", "9", "{F9}", "0", "{F10}", "a", "{F11}", "b", "{F12}", "A", "{F11}", "B", "{F12}")
            fTarget := output
            if fkeyMap.Has(fTarget) {
                ; Extrair modificadores remanescentes (^, !, +, #)
                modOnly := pendingModifiers
                SendToSystem(modOnly . fkeyMap[fTarget])
                LogBuffers("FKey Resolved: " . modOnly . fkeyMap[fTarget])
            } else {
                ; Tecla não reconhecida para FKey, enviar como comando direto
                modOnly := pendingModifiers
                SendToSystem(modOnly . output)
                LogBuffers("FKey Fallback: " . modOnly . output)
            }
            pendingModifiers := ""
            pendingAccent := ""
            UpdateOSD()
            return
        }

        if pendingSpecial == "M:" {
            ; Layout Kumara Elite K552 (Fn+F1 a Fn+F12)
            ; 1=MyPC 2=Search 3=Calc 4=Player 5=Prev 6=Next 7=Play/Pause 8=Stop 9=Mute 0=Vol- a=Vol+ b=Lock
            mkeyMap := Map("1", "#e", "2", "#s", "3", "{Launch_App2}", "4", "{Launch_Media}", "5", "{Media_Prev}", "6", "{Media_Next}", "7", "{Media_Play_Pause}", "8", "{Media_Stop}", "9", "{Volume_Mute}", "0", "{Volume_Down}", "a", "{Volume_Up}", "A", "{Volume_Up}")
            mTarget := output
            if mkeyMap.Has(mTarget) {
                modOnly := pendingModifiers
                SendToSystem(modOnly . mkeyMap[mTarget])
                LogBuffers("MKey Resolved: " . modOnly . mkeyMap[mTarget])
            } else {
                modOnly := pendingModifiers
                SendToSystem(modOnly . output)
                LogBuffers("MKey Fallback: " . modOnly . output)
            }
            pendingModifiers := ""
            pendingAccent := ""
            UpdateOSD()
            return
        }

        if pendingSpecial == "X:" {
            ; O output aqui é o caractere decodificado pelo morseMap
            ; Aceita tanto letras (a,b,c,d) quanto números (1,2,3,4)
            pyPath := '"' . A_ScriptDir . '\python\python.exe"'
            macroMap := Map("a", "3dPrecifier.py", "1", "3dPrecifier.py", "b", "SemantiCron.py", "2", "SemantiCron.py", "c", "dork.py", "3", "dork.py", "d", "websocket_server.py", "4", "websocket_server.py")
            mTarget := output
            if macroMap.Has(mTarget) {
                scriptPath := '"' . A_ScriptDir . '\' . macroMap[mTarget] . '"'
                Run(pyPath . ' ' . scriptPath, A_ScriptDir)
                LogBuffers("MacroKey Resolved: " . macroMap[mTarget] . " (input: " . output . ")")
                ToolTip("Macro: " . macroMap[mTarget], A_ScreenWidth / 2 - 80, A_ScreenHeight / 2)
                SetTimer(() => ToolTip(), -2000)
            } else {
                LogBuffers("MacroKey Fallback: tecla não mapeada (" . output . ")")
                ToolTip("Macro não mapeada: '" . output . "'", A_ScreenWidth / 2 - 100, A_ScreenHeight / 2)
                SetTimer(() => ToolTip(), -2000)
            }
            pendingModifiers := ""
            pendingAccent := ""
            UpdateOSD()
            return
        }

        ; Verificar se é um comando de sistema (teclas especiais, atalhos)
        isCommand := ((SubStr(output, 1, 1) = "^" && StrLen(output) > 1)
            || (SubStr(output, 1, 1) = "!" && StrLen(output) > 1)
            || (SubStr(output, 1, 1) = "#" && StrLen(output) > 1)
            || (SubStr(output, 1, 1) = "+" && StrLen(output) > 1)
            || (SubStr(output, 1, 1) = "{" && SubStr(output, -1) = "}")
            || (SubStr(output, 1, 2) = "+{" && SubStr(output, -1) = "}"))
            && !InStr(output, "Space") && !InStr(output, "Enter")
            && !InStr(output, "Backspace") && !InStr(output, "Escape")

        accentChars := pendingAccent
        modifierChars := pendingModifiers

        if isCommand {
            ; Comando de sistema → enviar com modificadores prepend
            if modifierChars != ""
                SendToSystem(modifierChars . output)
            else
                SendToSystem(output)
            LogBuffers("Executed Command: " . modifierChars . output)
            pendingModifiers := ""
            pendingAccent := ""
        } else {
            ; Comandos que alteram o buffer em tempo real
            if output = "{Space}" || output = "" || output = " " {
                wordBuffer .= " "
                visualBuffer := ""
                if modifierChars != ""
                    SendToSystem(modifierChars . "{Space}")
                else
                    SendToSystem("{Space}")
                LearnWordContext()
                pendingModifiers := ""
            pendingAccent := ""
            } else if output = "{Enter}" {
                wordBuffer .= "`n"
                visualBuffer := ""
                if modifierChars != ""
                    SendToSystem(modifierChars . "{Enter}")
                else
                    SendToSystem("{Enter}")
                LearnWordContext()
                pendingModifiers := ""
            pendingAccent := ""
            } else if output = "{Backspace}" {
                if wordBuffer != "" {
                    wordBuffer := SubStr(wordBuffer, 1, -1)
                    UpdateVisualBufferFromWordBuffer()
                }
                SendToSystem("{Backspace}")
                pendingModifiers := ""
            pendingAccent := ""
            } else if output = "^{Backspace}" {
                DeleteLastWord()
                pendingModifiers := ""
            pendingAccent := ""
            } else if output = "{Escape}" {
                wordBuffer := ""
                visualBuffer := ""
                SendToSystem("{Escape}")
                pendingModifiers := ""
            pendingAccent := ""
            } else {
                ; Caractere normal — montar envio com acentos e modificadores
                finalChar := output
                if accentChars != "" {
                    finalChar := CombineAccent(SubStr(accentChars, -1), output)
                    if !adbMode {
                        ; No Windows, enviamos os acentos separados como dead keys para o SO processar (ex: ´ + a)
                        Loop Parse, accentChars {
                            Send("{Blind}{" . A_LoopField . "}")
                        }
                    }
                }

                if modifierChars != "" {
                    if adbMode && accentChars != "" {
                        SendToSystem(modifierChars . finalChar)
                    } else {
                        SendToSystem(modifierChars . output)
                    }
                } else {
                    if adbMode && accentChars != "" {
                        SendToSystem(finalChar)
                    } else {
                        SendToSystem(output)
                    }
                    if modifierChars == "" {
                        wordBuffer .= finalChar
                        visualBuffer .= finalChar
                    }
                }
                pendingModifiers := ""
            pendingAccent := ""
            }
            LogBuffers("Added Character: " . output)
        }
    } else {
        LogBuffers("Invalid Sequence")
    }

    UpdateOSD()
}

AddToSequence(key) {
    global currentSequence
    currentSequence .= key
    LogBuffers("AddToSequence: " . key)
    UpdateOSD()
}

CancelSequence() {
    global currentSequence, wordBuffer, visualBuffer, historyBuffer
    LogBuffers("CancelSequence Start")
    if currentSequence != "" {
        currentSequence := ""
    } else {
        wordBuffer := ""
        visualBuffer := ""
        historyBuffer := []
    }
    LogBuffers("CancelSequence End")
    UpdateOSD()
}

DeleteLastWord() {
    global currentSequence, wordBuffer, visualBuffer, historyBuffer
    LogBuffers("DeleteLastWord Start")
    if currentSequence != "" {
        currentSequence := ""
    } else {
        if wordBuffer != "" {
            wordBuffer := RegExReplace(wordBuffer, "\s*\S+\s*$", "")
            UpdateVisualBufferFromWordBuffer()
        }
        SendToSystem("^{Backspace}")
    }
    LogBuffers("DeleteLastWord End")
    UpdateOSD()
}
CombineAccent(accent, char) {
    if accent = "´" {
        MapA := Map("a", "á", "e", "é", "i", "í", "o", "ó", "u", "ú", "A", "Á", "E", "É", "I", "Í", "O", "Ó", "U", "Ú", "c", "ç", "C", "Ç")
        return MapA.Has(char) ? MapA[char] : char
    }
    if accent = "~" {
        MapT := Map("a", "ã", "o", "õ", "n", "ñ", "A", "Ã", "O", "Õ", "N", "Ñ")
        return MapT.Has(char) ? MapT[char] : char
    }
    if accent = "^" {
        MapC := Map("a", "â", "e", "ê", "i", "î", "o", "ô", "u", "û", "A", "Â", "E", "Ê", "I", "Î", "O", "Ô", "U", "Û")
        return MapC.Has(char) ? MapC[char] : char
    }
    if accent = "``" {
        MapG := Map("a", "à", "e", "è", "i", "ì", "o", "ò", "u", "ù", "A", "À", "E", "È", "I", "Ì", "O", "Ò", "U", "Ù")
        return MapG.Has(char) ? MapG[char] : char
    }
    return char
}
