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
        http.open("POST", "http://localhost:8766/state", true)
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

GetAutocompleteSuggestion(word) {
    global dictArray
    if (word = "" || StrLen(word) < 2)
        return ""
    
    isFirstUpper := IsUpper(SubStr(word, 1, 1))
    
    wordLower := RemoveAccents(StrLower(word))
    for index, dictEntry in dictArray {
        if (StrLen(dictEntry.key) >= StrLen(wordLower)) {
            if (SubStr(dictEntry.key, 1, StrLen(wordLower)) = wordLower) {
                suggestion := dictEntry.word
                if (isFirstUpper) {
                    suggestion := StrUpper(SubStr(suggestion, 1, 1)) . SubStr(suggestion, 2)
                }
                return suggestion
            }
        }
    }
    return ""
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

ProcessSequence() {
    global currentSequence, morseMap, wordBuffer, visualBuffer

    if currentSequence = ""
        return

    seq := currentSequence
    currentSequence := ""
    
    LogBuffers("ProcessSequence Start (seq: " . seq . ")")

    if morseMap.Has(seq) {
        output := morseMap[seq]

        ; Verificar se é um comando de sistema
        isCommand := ((SubStr(output, 1, 1) = "^" && StrLen(output) > 1)
                  || (SubStr(output, 1, 1) = "{" && SubStr(output, -1) = "}")
                  || (SubStr(output, 1, 2) = "+{" && SubStr(output, -1) = "}"))
                  && !InStr(output, "Space") && !InStr(output, "Enter") 
                  && !InStr(output, "Backspace") && !InStr(output, "Escape")

        if isCommand {
            Send(output)
            LogBuffers("Executed Command: " . output)
        } else {
            ; Comandos que alteram o buffer em tempo real
            if output = "{Space}" || output = "" || output = " " {
                wordBuffer .= " "
                visualBuffer := ""
                Send("{Space}")
            } else if output = "{Enter}" {
                wordBuffer .= "`n"
                visualBuffer := ""
                Send("{Enter}")
            } else if output = "{Backspace}" {
                if wordBuffer != "" {
                    wordBuffer := SubStr(wordBuffer, 1, -1)
                    UpdateVisualBufferFromWordBuffer()
                }
                Send("{Backspace}")
            } else if output = "^{Backspace}" {
                DeleteLastWord()
            } else if output = "{Escape}" {
                wordBuffer := ""
                visualBuffer := ""
                Send("{Escape}")
            } else {
                wordBuffer .= output
                visualBuffer .= output
                SendText(output)
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
        Send("^{Backspace}")
    }
    LogBuffers("DeleteLastWord End")
    UpdateOSD()
}

