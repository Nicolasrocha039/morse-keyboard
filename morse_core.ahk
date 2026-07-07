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
            ToolTip("ADB Mode: ON`nKeys will be sent to Android", A_ScreenWidth/2 - 150, A_ScreenHeight/2)
        else
            ToolTip("ADB Mode: OFF`nKeys will be sent to Windows", A_ScreenWidth/2 - 150, A_ScreenHeight/2)
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
        ToolTip("Mouse Esq " . (lbuttonLocked ? "BLOQUEADO (Limpa buffers)" : "LIBERADO (Clique normal)"), A_ScreenWidth/2 - 150, A_ScreenHeight/2)
        SetTimer(() => ToolTip(), -2500)
        LogBuffers("Toggle LButton Locked: " . (lbuttonLocked ? "ON" : "OFF"))
        return
    }

    if output = "{ToggleTraditionalMode}" {
        global traditionalMode
        LoadConfig(!traditionalMode)
        ToolTip("Layout Tradicional " . (traditionalMode ? "ATIVADO" : "DESATIVADO"), A_ScreenWidth/2 - 150, A_ScreenHeight/2)
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
            ToolTip("Comando de Bluetooth enviado via ADB", A_ScreenWidth/2 - 150, A_ScreenHeight/2)
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
            ToolTip("Automação de conexão Bluetooth executada", A_ScreenWidth/2 - 150, A_ScreenHeight/2)
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

        ; === DEAD KEYS: Modificadores e Acentos acumulam no pendingPrefix ===
        global pendingPrefix
        if !IsSet(pendingPrefix)
            pendingPrefix := ""

        ; Modificadores sticky → acumulam prefixo AHK (^, !, +, #)
        if output = "{Ctrl}" {
            if InStr(pendingPrefix, "^")
                pendingPrefix := StrReplace(pendingPrefix, "^", "")
            else
                pendingPrefix .= "^"
            ToolTip("Prefixo: " . (pendingPrefix != "" ? pendingPrefix : "(nenhum)"), A_ScreenWidth/2 - 80, A_ScreenHeight/2)
            SetTimer(() => ToolTip(), -1500)
            LogBuffers("Modifier Prefix Toggle Ctrl → pendingPrefix: " . pendingPrefix)
            UpdateOSD()
            return
        }
        if output = "{Shift}" {
            if InStr(pendingPrefix, "+")
                pendingPrefix := StrReplace(pendingPrefix, "+", "")
            else
                pendingPrefix .= "+"
            ToolTip("Prefixo: " . (pendingPrefix != "" ? pendingPrefix : "(nenhum)"), A_ScreenWidth/2 - 80, A_ScreenHeight/2)
            SetTimer(() => ToolTip(), -1500)
            LogBuffers("Modifier Prefix Toggle Shift → pendingPrefix: " . pendingPrefix)
            UpdateOSD()
            return
        }
        if output = "{Alt}" {
            if InStr(pendingPrefix, "!")
                pendingPrefix := StrReplace(pendingPrefix, "!", "")
            else
                pendingPrefix .= "!"
            ToolTip("Prefixo: " . (pendingPrefix != "" ? pendingPrefix : "(nenhum)"), A_ScreenWidth/2 - 80, A_ScreenHeight/2)
            SetTimer(() => ToolTip(), -1500)
            LogBuffers("Modifier Prefix Toggle Alt → pendingPrefix: " . pendingPrefix)
            UpdateOSD()
            return
        }
        if output = "{LWin}" || output = "{RWin}" {
            if InStr(pendingPrefix, "#")
                pendingPrefix := StrReplace(pendingPrefix, "#", "")
            else
                pendingPrefix .= "#"
            ToolTip("Prefixo: " . (pendingPrefix != "" ? pendingPrefix : "(nenhum)"), A_ScreenWidth/2 - 80, A_ScreenHeight/2)
            SetTimer(() => ToolTip(), -1500)
            LogBuffers("Modifier Prefix Toggle Win → pendingPrefix: " . pendingPrefix)
            UpdateOSD()
            return
        }

        ; Acentos (dead keys) → acumulam no prefixo como caractere literal
        if output = "^" || output = "~" || output = "´" || output = "``" {
            pendingPrefix .= output
            ToolTip("Acento pendente: " . pendingPrefix, A_ScreenWidth/2 - 80, A_ScreenHeight/2)
            SetTimer(() => ToolTip(), -1500)
            LogBuffers("Accent Prefix: " . pendingPrefix)
            UpdateOSD()
            return
        }

        ; FKey / MKey → acumulam marcador especial no prefixo
        if output = "{FKey}" {
            pendingPrefix .= "F:"
            ToolTip("Prefixo F-Key: aguardando número (1-9, 0=F10, a=F11, b=F12)", A_ScreenWidth/2 - 180, A_ScreenHeight/2)
            SetTimer(() => ToolTip(), -3000)
            LogBuffers("FKey Prefix: " . pendingPrefix)
            UpdateOSD()
            return
        }
        if output = "{MKey}" {
            pendingPrefix .= "M:"
            ToolTip("Prefixo Media: 1=Play 2=Stop 3=Prev 4=Next 5=Vol+ 6=Vol- 7=Mute", A_ScreenWidth/2 - 220, A_ScreenHeight/2)
            SetTimer(() => ToolTip(), -3000)
            LogBuffers("MKey Prefix: " . pendingPrefix)
            UpdateOSD()
            return
        }
        if output = "{MacroKey}" {
            pendingPrefix .= "X:"
            ToolTip("Prefixo Macro: 1=3dPrecifier 2=SemantiCron 3=Dork", A_ScreenWidth/2 - 180, A_ScreenHeight/2)
            SetTimer(() => ToolTip(), -3000)
            LogBuffers("MacroKey Prefix: " . pendingPrefix)
            UpdateOSD()
            return
        }

        ; === A partir daqui, é uma tecla final — montar o envio completo ===

        ; Resolver FKey / MKey se estão no pendingPrefix
        if InStr(pendingPrefix, "F:") {
            ; Mapear o output (número/letra) para a tecla F correspondente
            fkeyMap := Map("1", "{F1}", "2", "{F2}", "3", "{F3}", "4", "{F4}", "5", "{F5}", "6", "{F6}", "7", "{F7}", "8", "{F8}", "9", "{F9}", "0", "{F10}", "a", "{F11}", "b", "{F12}")
            fTarget := output
            if fkeyMap.Has(fTarget) {
                ; Extrair modificadores remanescentes (^, !, +, #)
                modOnly := StrReplace(pendingPrefix, "F:", "")
                SendToSystem(modOnly . fkeyMap[fTarget])
                LogBuffers("FKey Resolved: " . modOnly . fkeyMap[fTarget])
            } else {
                ; Tecla não reconhecida para FKey, enviar como comando direto
                modOnly := StrReplace(pendingPrefix, "F:", "")
                SendToSystem(modOnly . output)
                LogBuffers("FKey Fallback: " . modOnly . output)
            }
            pendingPrefix := ""
            UpdateOSD()
            return
        }

        if InStr(pendingPrefix, "M:") {
            ; Mapear o output para a tecla de mídia correspondente
            mkeyMap := Map("1", "{Media_Play_Pause}", "2", "{Media_Stop}", "3", "{Media_Prev}", "4", "{Media_Next}", "5", "{Volume_Up}", "6", "{Volume_Down}", "7", "{Volume_Mute}")
            mTarget := output
            if mkeyMap.Has(mTarget) {
                modOnly := StrReplace(pendingPrefix, "M:", "")
                SendToSystem(modOnly . mkeyMap[mTarget])
                LogBuffers("MKey Resolved: " . modOnly . mkeyMap[mTarget])
            } else {
                modOnly := StrReplace(pendingPrefix, "M:", "")
                SendToSystem(modOnly . output)
                LogBuffers("MKey Fallback: " . modOnly . output)
            }
            pendingPrefix := ""
            UpdateOSD()
            return
        }

        if InStr(pendingPrefix, "X:") {
            ; Mapear o output para a macro correspondente
            pyPath := '"' . A_ScriptDir . '\python\python.exe"'
            macroMap := Map("1", "3dPrecifier.py", "2", "SemantiCron.py", "3", "dork.py", "4", "websocket_server.py")
            mTarget := output
            if macroMap.Has(mTarget) {
                scriptPath := '"' . A_ScriptDir . '\' . macroMap[mTarget] . '"'
                Run(pyPath . ' ' . scriptPath, A_ScriptDir, "Hide")
                LogBuffers("MacroKey Resolved: " . macroMap[mTarget])
                ToolTip("Macro: " . macroMap[mTarget], A_ScreenWidth/2 - 80, A_ScreenHeight/2)
                SetTimer(() => ToolTip(), -2000)
            } else {
                LogBuffers("MacroKey Fallback: tecla não mapeada (" . output . ")")
                ToolTip("Macro não encontrada para: " . output, A_ScreenWidth/2 - 100, A_ScreenHeight/2)
                SetTimer(() => ToolTip(), -2000)
            }
            pendingPrefix := ""
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

        ; Separar acentos e modificadores do pendingPrefix
        accentChars := ""
        modifierChars := ""
        if pendingPrefix != "" {
            Loop Parse, pendingPrefix {
                ch := A_LoopField
                if ch = "^" || ch = "!" || ch = "+" || ch = "#"
                    modifierChars .= ch
                else
                    accentChars .= ch ; ´, ~, `, ^(acento)
            }
        }

        if isCommand {
            ; Comando de sistema → enviar com modificadores prepend
            if modifierChars != ""
                SendToSystem(modifierChars . output)
            else
                SendToSystem(output)
            LogBuffers("Executed Command: " . modifierChars . output)
            pendingPrefix := ""
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
                pendingPrefix := ""
            } else if output = "{Enter}" {
                wordBuffer .= "`n"
                visualBuffer := ""
                if modifierChars != ""
                    SendToSystem(modifierChars . "{Enter}")
                else
                    SendToSystem("{Enter}")
                LearnWordContext()
                pendingPrefix := ""
            } else if output = "{Backspace}" {
                if wordBuffer != "" {
                    wordBuffer := SubStr(wordBuffer, 1, -1)
                    UpdateVisualBufferFromWordBuffer()
                }
                SendToSystem("{Backspace}")
                pendingPrefix := ""
            } else if output = "^{Backspace}" {
                DeleteLastWord()
                pendingPrefix := ""
            } else if output = "{Escape}" {
                wordBuffer := ""
                visualBuffer := ""
                SendToSystem("{Escape}")
                pendingPrefix := ""
            } else {
                ; Caractere normal — montar envio com acentos e modificadores
                if accentChars != "" {
                    ; Enviar cada acento como dead key seguido da letra
                    ; Ex: ´ + a → á (o Windows combina automaticamente)
                    Loop Parse, accentChars {
                        Send("{Blind}{" . A_LoopField . "}")
                    }
                }
                if modifierChars != "" {
                    ; Atalho com modificador: ^c, !{F4}, etc.
                    SendToSystem(modifierChars . output)
                } else {
                    ; Letra normal (possivelmente precedida de acento dead key)
                    wordBuffer .= output
                    visualBuffer .= output
                    SendToSystem(output)
                }
                pendingPrefix := ""
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

