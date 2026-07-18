#Requires AutoHotkey v2.0
global isSpecialLocked := false

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
    global wordBuffer, visualBuffer, cursorOffset
    if wordBuffer = "" {
        visualBuffer := ""
        return
    }
    cursorPos := StrLen(wordBuffer) - cursorOffset

    ; Find the last space before or at cursorPos
    lastSpace := 0
    Loop cursorPos {
        if SubStr(wordBuffer, A_Index, 1) = " " {
            lastSpace := A_Index
        }
    }

    ; Find the first space after cursorPos
    nextSpace := StrLen(wordBuffer) + 1
    Loop StrLen(wordBuffer) - cursorPos {
        if SubStr(wordBuffer, cursorPos + A_Index, 1) = " " {
            nextSpace := cursorPos + A_Index
            break
        }
    }

    visualBuffer := SubStr(wordBuffer, lastSpace + 1, nextSpace - lastSpace - 1)
}

LogBuffers(action) {
    global wordBuffer, visualBuffer, currentSequence
    try {
        FileAppend("[" . A_Now . "] Action: " . action . " | seq: '" . currentSequence . "' | word: '" . wordBuffer . "' | vis: '" . visualBuffer . "'`n", "logs\debug_buffer.txt", "UTF-8")
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
        UpdateOSD()
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

    if output = "{TobiiF2}" {
        prevHidden := A_DetectHiddenWindows
        DetectHiddenWindows(True)

        if WinExist("ahk_exe TobiiDynavox.WindowsControl.Settings.exe") {
            ControlSend("{F2}", , "ahk_exe TobiiDynavox.WindowsControl.Settings.exe")
            LogBuffers("Tobii F2 Command Sent")
        } else if WinExist("Windows Control") {
            ControlSend("{F2}", , "Windows Control")
            LogBuffers("Tobii F2 Command Sent (by Title)")
        } else {
            LogBuffers("Tobii F2 Failed: Not Found")
        }

        DetectHiddenWindows(prevHidden)
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

    if output = "{ToggleCapsLock}" {
        global morseCapsLock
        if !IsSet(morseCapsLock)
            morseCapsLock := false
        morseCapsLock := !morseCapsLock
        ToolTip("Caps Lock Automático " . (morseCapsLock ? "ATIVADO" : "DESATIVADO"), A_ScreenWidth / 2 - 150, A_ScreenHeight / 2)
        SetTimer(() => ToolTip(), -2500)
        LogBuffers("Toggle CapsLock: " . (morseCapsLock ? "ON" : "OFF"))
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
            RunWait(adbPath . " shell input keyevent 61", , "Hide") ; TAB (Navegação)
        } else if output = "+{Tab}" {
            ; Enviar Shift + Tab para voltar foco (requer keycombination em Androids recentes)
            RunWait(adbPath . " shell input keycombination 59 61", , "Hide")
        } else if output = "{AppSwitch}" || output = "{LWin}" {
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
                LogBuffers("ADB Cmd: " . adbCmd)
                ToolTip("ADB: " . adbCmd, A_ScreenWidth / 2 - 200, A_ScreenHeight / 2)
                SetTimer(() => ToolTip(), -2500)
                RunWait(adbCmd, , "Hide")
            }
        } else {
            ; Usando o ADBKeyBoard para suportar acentos e caracteres especiais nativamente
            escapedOutput := StrReplace(output, "'", "'\''")

            ; Envia os caracteres usando o Intent de broadcast do ADBKeyBoard
            adbCmd := adbPath . ' shell am broadcast -a ADB_INPUT_TEXT --es msg ' . "'" . escapedOutput . "'"
            LogBuffers("ADB Cmd: " . adbCmd)
            ToolTip("ADB: " . adbCmd, A_ScreenWidth / 2 - 200, A_ScreenHeight / 2)
            SetTimer(() => ToolTip(), -2500)
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
    global currentSequence, morseMap, wordBuffer, visualBuffer, adbMode, cursorOffset, textSelectedAll

    if currentSequence = ""
        return

    seq := currentSequence
    currentSequence := ""

    LogBuffers("ProcessSequence Start (seq: " . seq . ")")

    if morseMap.Has(seq) {
        output := morseMap[seq]

        if output = "{RepeatLast}" {
            global lastSentCommand, lastSentModifiers, lastSentAccent, lastSentSpecial
            if lastSentCommand != "" {
                output := lastSentCommand
                global pendingModifiers, pendingAccent, pendingSpecial, isSpecialLocked
                if IsSet(lastSentModifiers)
                    pendingModifiers := lastSentModifiers
                if IsSet(lastSentAccent)
                    pendingAccent := lastSentAccent
                if IsSet(lastSentSpecial)
                    pendingSpecial := lastSentSpecial
            } else {
                return ; Nada para repetir
            }
        } else {
            global lastSentCommand, lastSentModifiers, lastSentAccent, lastSentSpecial
            global pendingModifiers, pendingAccent, pendingSpecial, isSpecialLocked
            lastSentCommand := output
            lastSentModifiers := IsSet(pendingModifiers) ? pendingModifiers : ""
            lastSentAccent := IsSet(pendingAccent) ? pendingAccent : ""
            lastSentSpecial := IsSet(pendingSpecial) ? pendingSpecial : ""
        }

        ; === DEAD KEYS: Modificadores e Acentos acumulam separadamente ===
        global pendingModifiers, pendingAccent, pendingSpecial, isSpecialLocked
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

        if output = "{WinMenu}" {
            SendToSystem("^{Esc}")
            LogBuffers("WinMenu Triggered")
            UpdateOSD()
            return
        }

        if output = "{QuotesLeft}" {
            hasShift := InStr(pendingModifiers, "+")
            insertedString := hasShift ? '""' : "''"

            if hasShift {
                SendToSystem('""')
                SendToSystem("{Left}")
                pendingModifiers := StrReplace(pendingModifiers, "+", "")
            } else {
                SendToSystem("''")
                SendToSystem("{Left}")
            }

            if cursorOffset > 0 {
                leftPart := SubStr(wordBuffer, 1, StrLen(wordBuffer) - cursorOffset)
                rightPart := SubStr(wordBuffer, StrLen(wordBuffer) - cursorOffset + 1)
                wordBuffer := leftPart . insertedString . rightPart
            } else {
                wordBuffer .= insertedString
            }
            cursorOffset++
            UpdateVisualBufferFromWordBuffer()

            LogBuffers("QuotesLeft executed")
            UpdateOSD()
            return
        }

        ; Acentos (dead keys) → acumulam no prefixo como caractere literal
        if output = "^" || output = "~" || output = "´" || output = "``" {
            if (pendingAccent == output) {
                pendingAccent := ""
                ToolTip("Acento pendente: Desativado", A_ScreenWidth / 2 - 80, A_ScreenHeight / 2)
            } else {
                pendingAccent := output
                ToolTip("Acento pendente: " . pendingAccent, A_ScreenWidth / 2 - 80, A_ScreenHeight / 2)
            }
            SetTimer(() => ToolTip(), -1500)
            LogBuffers("Accent: " . pendingAccent)
            UpdateOSD()
            return
        }

        ; FKey, MKey, MacroKey e teclas personalizadas genéricas (*Key) → toggle no prefixo
        if RegExMatch(output, "^\{[a-zA-Z0-9]+Key\}$") {
            if (pendingSpecial == output) {
                pendingSpecial := ""
                isSpecialLocked := false
                ToolTip("Prefixo " . output . ": Desativado", A_ScreenWidth / 2 - 180, A_ScreenHeight / 2)
            } else {
                pendingSpecial := output
                if (output == "{FKey}")
                    ToolTip("Prefixo F-Key: aguardando número (1-9, 0=F10, a=F11, b=F12)", A_ScreenWidth / 2 - 180, A_ScreenHeight / 2)
                else if (output == "{MKey}")
                    ToolTip("Media (Kumara): 1=PC 2=Search 3=Calc 4=Player 5=Prev 6=Next 7=Play 8=Stop 9=Mute 0=Vol- a=Vol+", A_ScreenWidth / 2 - 300, A_ScreenHeight / 2)
                else if (output == "{MacroKey}")
                    ToolTip("Prefixo Macro: 1=3dPrecifier 2=SemantiCron 3=Dork", A_ScreenWidth / 2 - 180, A_ScreenHeight / 2)
                else if (output == "{SpotifyKey}")
                    ToolTip("Spotify: 1=Shuf 2=Rep 3=Like 4=Seek- 5=Seek+ 6=Srch", A_ScreenWidth / 2 - 250, A_ScreenHeight / 2)
                else if (output == "{TeamsKey}")
                    ToolTip("Teams: 1=Mic 2=Cam 3=Share 4=Hand 5=Leave 6=Chat", A_ScreenWidth / 2 - 250, A_ScreenHeight / 2)
                else
                    ToolTip("Prefixo Customizado: " . output, A_ScreenWidth / 2 - 180, A_ScreenHeight / 2)
            }
            SetTimer(() => ToolTip(), -3000)
            LogBuffers("Special Prefix: " . pendingSpecial)
            UpdateOSD()
            return
        }

        ; === A partir daqui, é uma tecla final — montar o envio completo ===


        if pendingSpecial != "" {
            ; Remover chaves do pendingSpecial para pegar o nome. Ex: "{SiteKey}" -> "SiteKey"
            prefixName := SubStr(pendingSpecial, 2, StrLen(pendingSpecial) - 2)
            mapFile := A_ScriptDir . "\" . prefixName . ".txt"
            
            global customKeysCache
            resolved := false
            if customKeysCache.Has(prefixName) && customKeysCache[prefixName].Has(output) {
                targetValue := customKeysCache[prefixName][output]

                if (targetValue != "") {
                    actionType := "text"
                    target := targetValue
                    payload := ""
                    
                    if InStr(targetValue, "|") {
                        valParts := StrSplit(targetValue, "|")
                        actionType := valParts[1]
                        target := valParts[2]
                        if valParts.Length > 2
                            payload := valParts[3]
                    } else {
                        if SubStr(targetValue, 1, 4) == "http"
                            actionType := "site"
                        else if InStr(targetValue, ".py")
                            actionType := "python"
                        else if InStr(targetValue, ".exe") || InStr(targetValue, ".bat")
                            actionType := "app"
                    }
                    
                    ExecuteCustomAction(actionType, target, payload, pendingModifiers)
                    LogBuffers(prefixName . " Resolved via txt: " . targetValue)
                    resolved := true
                }
            }
            
            if !resolved {
                ; VERIFICAR SE O OUTPUT É OUTRA TECLA ESPECIAL
                if RegExMatch(output, "^\{([a-zA-Z0-9]+Key)\}$") {
                    pendingSpecial := output
                    UpdateOSD()
                    return
                }

                if (output == "{ToggleLock}") {
                    isSpecialLocked := !isSpecialLocked
                    if (!isSpecialLocked) {
                        pendingSpecial := ""
                    }
                    UpdateOSD()
                    return
                }

                if (output == "{Escape}") {
                    pendingSpecial := ""
                    isSpecialLocked := false
                    UpdateOSD()
                    return
                }

                modOnly := pendingModifiers
                SendToSystem(modOnly . output)
                LogBuffers("CustomKey (" . pendingSpecial . ") Fallback: " . modOnly . output)
            }
            
            if (!isSpecialLocked) {
                pendingSpecial := ""
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

            ; Rastrear cursor virtual para navega��o
            if (output = "{Left}") {
                textSelectedAll := false
                if (cursorOffset < StrLen(wordBuffer))
                    cursorOffset++
                UpdateVisualBufferFromWordBuffer()
            } else if (output = "{Right}") {
                textSelectedAll := false
                if (cursorOffset > 0)
                    cursorOffset--
                UpdateVisualBufferFromWordBuffer()
            } else if (output = "{Home}") {
                textSelectedAll := false
                cursorOffset := StrLen(wordBuffer)
                UpdateVisualBufferFromWordBuffer()
            } else if (output = "{End}") {
                textSelectedAll := false
                cursorOffset := 0
                UpdateVisualBufferFromWordBuffer()
            } else if (output = "{Delete}") {
                if textSelectedAll {
                    wordBuffer := ""
                    cursorOffset := 0
                    textSelectedAll := false
                    UpdateVisualBufferFromWordBuffer()
                } else if (cursorOffset > 0) {
                    leftPart := SubStr(wordBuffer, 1, StrLen(wordBuffer) - cursorOffset)
                    rightPart := SubStr(wordBuffer, StrLen(wordBuffer) - cursorOffset + 2)
                    wordBuffer := leftPart . rightPart
                    cursorOffset--
                    UpdateVisualBufferFromWordBuffer()
                }
            }

            LogBuffers("Executed Command: " . modifierChars . output)
            pendingModifiers := ""
            pendingAccent := ""
        } else {
            ; Comandos que alteram o buffer em tempo real
            if output = "{Space}" || output = "" || output = " " {
                if textSelectedAll {
                    wordBuffer := ""
                    cursorOffset := 0
                    textSelectedAll := false
                }
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
                if textSelectedAll {
                    wordBuffer := ""
                    cursorOffset := 0
                    textSelectedAll := false
                }
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
                if textSelectedAll {
                    wordBuffer := ""
                    cursorOffset := 0
                    textSelectedAll := false
                    UpdateVisualBufferFromWordBuffer()
                } else if wordBuffer != "" && cursorOffset <= StrLen(wordBuffer) {
                    leftPart := SubStr(wordBuffer, 1, StrLen(wordBuffer) - cursorOffset - 1)
                    rightPart := SubStr(wordBuffer, StrLen(wordBuffer) - cursorOffset + 1)
                    wordBuffer := leftPart . rightPart
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
                cursorOffset := 0
                visualBuffer := ""
                textSelectedAll := false
                SendToSystem("{Escape}")
                pendingModifiers := ""
                pendingAccent := ""
            } else {
                ; Caractere normal — montar envio com acentos e modificadores
                finalChar := output

                global morseCapsLock
                isCaps := IsSet(morseCapsLock) && morseCapsLock
                hasShift := InStr(modifierChars, "+")

                if isCaps && IsLower(output) {
                    if hasShift {
                        modifierChars := StrReplace(modifierChars, "+", "")
                    } else {
                        output := StrUpper(output)
                        finalChar := output
                    }
                } else if hasShift {
                    shiftedChar := ResolveShift(output)
                    if shiftedChar != output {
                        output := shiftedChar
                        finalChar := output
                        modifierChars := StrReplace(modifierChars, "+", "")
                    }
                }

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
                    if modifierChars == "^" && (output == "a" || output == "A") {
                        textSelectedAll := true
                    } else if modifierChars == "^" && (output == "v" || output == "V") {
                        ; Colar substitui selecao e insere texto desconhecido, entao limpamos o buffer
                        wordBuffer := ""
                        cursorOffset := 0
                        textSelectedAll := false
                        UpdateVisualBufferFromWordBuffer()
                    }
                    if adbMode && accentChars != "" {
                        SendToSystem(modifierChars . EscapeAHK(finalChar))
                    } else {
                        SendToSystem(modifierChars . EscapeAHK(output))
                    }
                } else {
                    if adbMode && accentChars != "" {
                        SendToSystem(EscapeAHK(finalChar))
                    } else {
                        SendToSystem(EscapeAHK(output))
                    }
                    if modifierChars == "" {
                        if textSelectedAll {
                            wordBuffer := ""
                            cursorOffset := 0
                            visualBuffer := ""
                            textSelectedAll := false
                        }
                        if cursorOffset > 0 {
                            leftPart := SubStr(wordBuffer, 1, StrLen(wordBuffer) - cursorOffset)
                            rightPart := SubStr(wordBuffer, StrLen(wordBuffer) - cursorOffset + 1)
                            wordBuffer := leftPart . finalChar . rightPart
                            UpdateVisualBufferFromWordBuffer()
                        } else {
                            wordBuffer .= finalChar
                            visualBuffer .= finalChar
                        }
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
    global currentSequence, wordBuffer, visualBuffer, historyBuffer, cursorOffset, textSelectedAll
    LogBuffers("CancelSequence Start")
    if currentSequence != "" {
        currentSequence := ""
    } else {
        wordBuffer := ""
        cursorOffset := 0
        textSelectedAll := false
        visualBuffer := ""
        historyBuffer := []
    }
    LogBuffers("CancelSequence End")
    UpdateOSD()
}

DeleteLastWord() {
    global currentSequence, wordBuffer, visualBuffer, historyBuffer, cursorOffset, textSelectedAll
    LogBuffers("DeleteLastWord Start")
    if currentSequence != "" {
        currentSequence := ""
    } else {
        if textSelectedAll {
            wordBuffer := ""
            cursorOffset := 0
            textSelectedAll := false
            visualBuffer := ""
        } else if wordBuffer != "" {
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

ResolveShift(char) {
    if (StrLen(char) != 1)
        return char
    if IsLower(char)
        return StrUpper(char)
    MapShift := Map(
        "/", "?",
        "1", "!",
        "2", "@",
        "3", "#",
        "4", "$",
        "5", "%",
        "6", "¨",
        "7", "&",
        "8", "*",
        "9", "(",
        "0", ")",
        "-", "_",
        "=", "+",
        "[", "{",
        "]", "}",
        ";", ":",
        "'", "`"",
        ",", "<",
        ".", ">",
        "\", "|"
    )
    if MapShift.Has(char)
        return MapShift[char]
    return char
}

EscapeAHK(char) {
    if (StrLen(char) == 1 && InStr("!#^+{}", char))
        return "{" . char . "}"
    return char
}

global SpotifyVolumeLevel := 4 ; 0 a 4 (0%, 25%, 50%, 75%, 100%)

AdjustSpotifyVolume(change) {
    global SpotifyVolumeLevel
    if (change == "MAX") {
        SpotifyVolumeLevel := 4
    } else {
        SpotifyVolumeLevel += change
        if (SpotifyVolumeLevel > 4)
            SpotifyVolumeLevel := 4
        if (SpotifyVolumeLevel < 0)
            SpotifyVolumeLevel := 0
    }

    ; Força o volume a partir do zero para contornar o gargalo de não salvar a % manual no AHK
    Send("{Ctrl down}{Down 50}{Ctrl up}")
    Sleep(50)

    if (SpotifyVolumeLevel == 1)
        Send("{Ctrl down}{Up 5}{Ctrl up}")  ; 25%
    else if (SpotifyVolumeLevel == 2)
        Send("{Ctrl down}{Up 10}{Ctrl up}") ; 50%
    else if (SpotifyVolumeLevel == 3)
        Send("{Ctrl down}{Up 15}{Ctrl up}") ; 75%
    else if (SpotifyVolumeLevel == 4)
        Send("{Ctrl down}{Up 50}{Ctrl up}") ; 100%
}

; Método dinâmico para ações customizadas
ExecuteCustomAction(actionType, target, payload := "", modifiers := "") {
    try {
        if (actionType = "text") {
            savedClip := ClipboardAll()
            A_Clipboard := target
            Sleep(50)
            Send("^{v}")
            Sleep(50)
            A_Clipboard := savedClip
        } else if (actionType = "send") {
            SendToSystem(modifiers . target)
        } else if (actionType = "site" || actionType = "app") {
            Run(target)
        } else if (actionType = "python") {
            scriptName := target
            args := ""
            if (pos := InStr(target, ".py ")) {
                scriptName := SubStr(target, 1, pos + 2)
                args := SubStr(target, pos + 4)
            }
            Run("python\python.exe `"scripts\" . scriptName . "`" " . args, , "Hide")
        } else if (actionType = "http") {
            req := ComObject("WinHttp.WinHttpRequest.5.1")
            ; Se não houver payload, tenta fazer um GET, se houver payload faz um POST
            method := (payload != "") ? "POST" : "GET"
            req.Open(method, target, true)
            req.SetRequestHeader("Content-Type", "application/json")
            if (payload != "")
                req.Send(payload)
            else
                req.Send()
        } else if (SubStr(actionType, 1, 8) = "spotify_") {
            if WinExist("ahk_exe Spotify.exe") {
                activeHwnd := WinExist("A")
                WinActivate("ahk_exe Spotify.exe")
                if WinWaitActive("ahk_exe Spotify.exe", , 1) {
                    if (actionType = "spotify_send") {
                        Send(target)
                    } else if (actionType = "spotify_python") {
                        WinGetPos(&spX, &spY, &spW, &spH, "ahk_exe Spotify.exe")
                        scriptName := target
                        args := spX . " " . spY . " " . spW . " " . spH
                        if (pos := InStr(target, ".py ")) {
                            scriptName := SubStr(target, 1, pos + 2)
                            args := SubStr(target, pos + 4) . " " . args
                        }
                        Run("python\python.exe `"scripts\" . scriptName . "`" " . args, , "Hide")
                    } else if (actionType = "spotify_func") {
                        if (target = "AdjustSpotifyVolume")
                            AdjustSpotifyVolume(payload)
                    }
                    Sleep(50)
                    if (activeHwnd)
                        WinActivate("ahk_id " . activeHwnd)
                }
            } else {
                ToolTip("Spotify nao esta aberto!", A_ScreenWidth / 2 - 100, A_ScreenHeight / 2)
                SetTimer(() => ToolTip(), -2000)
            }
        } else if (actionType = "func") {
            if (target = "ReloadConfig") {
                LoadConfig()
                ToolTip("Arquivos INI Recarregados!", A_ScreenWidth / 2 - 100, A_ScreenHeight / 2)
                SetTimer(() => ToolTip(), -2000)
            }
        }
    } catch as e {
        ToolTip("Erro CustomAction (" . actionType . "): " . e.Message, A_ScreenWidth / 2 - 150, A_ScreenHeight / 2)
        SetTimer(() => ToolTip(), -3000)
    }
}
