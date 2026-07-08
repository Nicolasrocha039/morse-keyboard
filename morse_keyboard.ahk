; ═══════════════════════════════════════════════════════════════════════════════
; MORSE KEYBOARD (v2.0) - Refatorado com SRP
; ═══════════════════════════════════════════════════════════════════════════════

#Requires AutoHotkey v2.0
#SingleInstance Force

; ── Configuração Global ──
global morseActive := false
global currentSequence := ""
global wordBuffer := ""      
global visualBuffer := ""    
global showMaps := true
global USE_BROWSER_OSD := false
global historyBuffer := []   
global adbMode := false
global lbuttonLocked := true
global lastSentCommand := ""
global pendingModifiers := ""
global pendingAccent := ""
global pendingSpecial := ""

; ── Importação dos Módulos ──
#Include "%A_ScriptDir%\morse_config.ahk"
#Include "%A_ScriptDir%\morse_core.ahk"
#Include "%A_ScriptDir%\morse_osd.ahk"

; ── Inicialização ──
try {
    Run('"' . A_ScriptDir . '\python\python.exe" "' . A_ScriptDir . '\websocket_server.py"', A_ScriptDir, "Hide")
}

UpdateOSD()

ToolTip("Morse Keyboard carregado!`nCapsLock para ativar/desativar", A_ScreenWidth/2 - 150, A_ScreenHeight/2 - 50)
SetTimer(() => ToolTip(), -2500)

; ═══════════════════════════════════════════════════════════════════════════════
; MOVIMENTAÇÃO DO OSD (Arrastar e Soltar)
; ═══════════════════════════════════════════════════════════════════════════════
WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    PostMessage(0xA1, 2, , , "ahk_id " hwnd)
}
OnMessage(0x0201, WM_LBUTTONDOWN)


; ═══════════════════════════════════════════════════════════════════════════════
; HOTKEYS
; ═══════════════════════════════════════════════════════════════════════════════

CapsLock:: {
    global morseActive
    morseActive := !morseActive
    LogBuffers("ToggleMorse Keyboard: " . (morseActive ? "ON" : "OFF"))
    UpdateOSD()

    if morseActive
        SoundBeep(600, 100), SoundBeep(900, 100)
    else
        SoundBeep(900, 100), SoundBeep(600, 100)
}

^!a:: {
    global adbMode
    adbMode := !adbMode
    if adbMode
        ToolTip("ADB Mode: ON`nKeys will be sent to Android", A_ScreenWidth/2 - 150, A_ScreenHeight/2)
    else
        ToolTip("ADB Mode: OFF`nKeys will be sent to Windows", A_ScreenWidth/2 - 150, A_ScreenHeight/2)
    SetTimer(() => ToolTip(), -2500)
    LogBuffers("Toggle ADB Mode: " . (adbMode ? "ON" : "OFF"))
}

#HotIf morseActive
Escape:: CancelSequence()
LWin:: CancelSequence()



#HotIf morseActive

\:: ToggleMaps()
b:: ToggleBrowserMode()

q:: AddToSequence("Q")
a:: AddToSequence("A")
Right:: AddToSequence("R")

$Backspace:: {
    global currentSequence, wordBuffer, visualBuffer, historyBuffer
    LogBuffers("Physical Backspace Start")
    if currentSequence != "" {
        currentSequence := SubStr(currentSequence, 1, -1)
    } else {
        if wordBuffer != "" {
            wordBuffer := SubStr(wordBuffer, 1, -1)
            UpdateVisualBufferFromWordBuffer()
        }
        SendToSystem("{Backspace}")
    }
    LogBuffers("Physical Backspace End")
    UpdateOSD()
}

$^Backspace:: {
    DeleteLastWord()
}

$Space:: {
    global currentSequence, wordBuffer, visualBuffer, historyBuffer
    LogBuffers("Physical Space Start")
    if currentSequence != "" {
        ProcessSequence()
    }
    wordBuffer .= " "
    visualBuffer := ""
    historyBuffer.Push(" ")
    LogBuffers("Physical Space End")
    UpdateOSD()
    LearnWordContext()
}

$Enter:: {
    global currentSequence, wordBuffer, visualBuffer, historyBuffer
    LogBuffers("Physical Enter Start")
    if currentSequence != "" {
        ProcessSequence()
    } else {
        suggestion := GetAutocompleteSuggestion(visualBuffer)
        if (suggestion != "") {
            ; Envia os backspaces e a sugestao
            loop StrLen(visualBuffer) {
                SendToSystem("{Backspace}")
            }
            SendToSystem(suggestion . " ")
            
            ; Adjust wordBuffer
            if (StrLen(wordBuffer) >= StrLen(visualBuffer)) {
                wordBuffer := SubStr(wordBuffer, 1, StrLen(wordBuffer) - StrLen(visualBuffer))
            }
            wordBuffer .= suggestion . " "
            
            visualBuffer := ""
            historyBuffer.Push(suggestion . " ")
            LogBuffers("Autocompleted/Corrected: " . suggestion)
            UpdateOSD()
            LearnWordContext()
        } else {
            wordBuffer := ""
            visualBuffer := ""
            historyBuffer := []
            LogBuffers("Cleared Word Buffer")
            SendToSystem("{Enter}")
            UpdateOSD()
            LearnWordContext()
        }
    }
    LogBuffers("Physical Enter End")
}
#HotIf morseActive && lbuttonLocked
$LButton:: {
    global currentSequence, wordBuffer, visualBuffer, historyBuffer
    LogBuffers("Physical LButton Down")

    ; Captura posição e tempo ao pressionar
    CoordMode("Mouse", "Screen")
    MouseGetPos(&lbDownX, &lbDownY)
    lbDownTime := A_TickCount

    ; Aguarda o botão ser solto (com timeout de 2s)
    KeyWait("LButton", "T2")

    ; Verifica se foi arraste (moveu > 5px ou ficou > 200ms)
    MouseGetPos(&lbUpX, &lbUpY)
    moved := Abs(lbUpX - lbDownX) + Abs(lbUpY - lbDownY)
    held := A_TickCount - lbDownTime

    if (moved > 5 || held > 200) {
        ; Foi um arraste ou clique longo — passa diretamente para o sistema
        Send("{Blind}{LButton Down}")
        Sleep(10)
        Send("{Blind}{LButton Up}")
        LogBuffers("LButton: drag/long-press passado ao sistema")
        return
    }

    ; Clique rápido — aplicar lógica morse/autocomplete
    if currentSequence != "" {
        ProcessSequence()
    } else {
        suggestion := GetAutocompleteSuggestion(visualBuffer)
        if (suggestion != "") {
            loop StrLen(visualBuffer) {
                SendToSystem("{Backspace}")
            }
            SendToSystem(suggestion . " ")
            if (StrLen(wordBuffer) >= StrLen(visualBuffer)) {
                wordBuffer := SubStr(wordBuffer, 1, StrLen(wordBuffer) - StrLen(visualBuffer))
            }
            wordBuffer .= suggestion . " "
            visualBuffer := ""
            historyBuffer.Push(suggestion . " ")
            LogBuffers("Autocompleted/Corrected: " . suggestion)
            UpdateOSD()
            LearnWordContext()
        } else {
            wordBuffer := ""
            visualBuffer := ""
            historyBuffer := []
            LogBuffers("Cleared Word Buffer")
            Send("{Blind}{LButton}")
            UpdateOSD()
            LearnWordContext()
        }
    }
    LogBuffers("Physical LButton End")
}
#HotIf

