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

; ── Importação dos Módulos ──
#Include "%A_ScriptDir%\morse_config.ahk"
#Include "%A_ScriptDir%\morse_core.ahk"
#Include "%A_ScriptDir%\morse_osd.ahk"

; ── Inicialização ──
try {
    Run('"C:\Program Files\Python313\python.exe" "' . A_ScriptDir . '\websocket_server.py"', A_ScriptDir, "Hide")
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

#HotIf morseActive
Escape:: CancelSequence()
LWin:: CancelSequence()

w:: TabGoLeft()
s:: TabGoRight()
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
        Send("{Backspace}")
    }
    LogBuffers("Physical Backspace End")
    UpdateOSD()
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
}

$Enter:: {
    global currentSequence, wordBuffer, visualBuffer, historyBuffer
    LogBuffers("Physical Enter Start")
    if currentSequence != "" {
        ProcessSequence()
    } else {
        wordBuffer := ""
        visualBuffer := ""
        historyBuffer := []
        LogBuffers("Cleared Word Buffer")
        Send("{Enter}")
        UpdateOSD()
    }
    LogBuffers("Physical Enter End")
}
#HotIf
