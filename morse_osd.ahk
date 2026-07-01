#Requires AutoHotkey v2.0

global MONO_FONT := "Consolas"

FormatForCard(val) {
    if val = "{Space}"
        return "Espaço"
    if val = "{Enter}"
        return "Enter"
    if val = "{Backspace}"
        return "Bksp"
    if val = "{Delete}"
        return "Del"
    if val = "{Tab}"
        return "Tab"
    if val = "{Escape}"
        return "Esc"
    if val = "{Up}"
        return "▲ Cima"
    if val = "{Down}"
        return "▼ Baixo"
    if val = "{Left}"
        return "◀ Esq"
    if val = "{Right}"
        return "▶ Dir"
    if val = "{Home}"
        return "Home"
    if val = "{End}"
        return "End"
    if val = "{PgUp}"
        return "PgUp"
    if val = "{PgDn}"
        return "PgDn"
    if val = "{Insert}"
        return "Ins"
    if SubStr(val, 1, 1) = "^"
        return "Ctrl+" . Format("{:U}", SubStr(val, 2))
    if SubStr(val, 1, 1) = "{" && SubStr(val, -1) = "}" {
        return SubStr(val, 2, -1)
    }
    return val
}

CreateKeyCard(guiObj, keyName, x, y) {
    card := guiObj.AddText("x" . x . " y" . y . " w105 h55 +Background0x1c1c2e +Border", "")
    label := guiObj.AddText("x" . (x+6) . " y" . (y+4) . " w40 h15 +BackgroundTrans c0x9999bb", keyName)
    label.SetFont("s8 Bold", "Segoe UI")
    val := guiObj.AddText("x" . (x+6) . " y" . (y+20) . " w93 h30 Center +BackgroundTrans cWhite", "")
    val.SetFont("s12 Bold", "Consolas")
    return {card: card, label: label, val: val}
}

UpdateCard(key, valText, isActive) {
    global cards
    cardObj := cards[key]
    
    if isActive {
        cardObj.card.Opt("+Background0x1c1c2e") ; Active card background
        cardObj.label.Opt("c0x9999bb")           ; Dim gold/white label
        cardObj.val.Opt("c0x00FFCC")             ; Neon cyan value
        cardObj.val.Text := valText
    } else {
        cardObj.card.Opt("+Background0x0b0b14") ; Inactive card background (same as GUI)
        cardObj.label.Opt("c0x222233")           ; Dim inactive label
        cardObj.val.Opt("c0x222233")             ; Dim inactive value
        cardObj.val.Text := "-"
    }
    cardObj.card.Redraw()
    cardObj.label.Redraw()
    cardObj.val.Redraw()
}

UpdateKeyGuide(seq) {
    global morseMap
    
    ; Mapeamento de tecla digitada para o nome correspondente do Card
    keyMapping := Map("Q", "Q", "A", "A", "R", "Right")
    
    for k, cardKey in keyMapping {
        nextSeq := seq . k
        
        ; 1. Check exact match
        if morseMap.Has(nextSeq) {
            val := morseMap[nextSeq]
            formattedVal := FormatForCard(val)
            UpdateCard(cardKey, formattedVal, true)
        }
        ; 2. Check if prefix for other sequences
        else {
            hasPrefix := false
            for mapKey, mapVal in morseMap {
                if StrLen(mapKey) > StrLen(nextSeq) && SubStr(mapKey, 1, StrLen(nextSeq)) = nextSeq {
                    hasPrefix := true
                    break
                }
            }
            if hasPrefix {
                UpdateCard(cardKey, "...", true)
            } else {
                UpdateCard(cardKey, "-", false)
            }
        }
    }
    
    ; O card do Enter sempre serve para confirmar
    UpdateCard("Enter", "Confirmar", true)
}

; ── GUI pequena (OFF) ──
global osdMini := Gui("+AlwaysOnTop -Caption +ToolWindow +Resize")
osdMini.BackColor := "0x12121e"
osdMini.MarginX := 10
osdMini.MarginY := 6

global miniStatus := osdMini.AddText("cWhite w200 Center", "⌨ MORSE KB: OFF")
miniStatus.SetFont("s10 Bold", "Segoe UI")

global miniHint := osdMini.AddText("c0x555577 w200 Center", "CapsLock para ativar")
miniHint.SetFont("s8", "Segoe UI")

osdMini.Show("x10 y10 NoActivate")
WinSetTransparent(220, osdMini)

; ── GUI completa (ON) ──
global osd := Gui("+AlwaysOnTop -Caption +ToolWindow +Resize", "MorseGuideOSD")
osd.BackColor := "0x0b0b14" ; Deep dark background
osd.MarginX := 15
osd.MarginY := 10

; Status e Informações da Sequência
global statusText := osd.AddText("x15 y10 w890 h24 c0x00FFCC", "⌨ MORSE KEYBOARD: ATIVO")
statusText.SetFont("s12 Bold", "Segoe UI")

global seqLabel := osd.AddText("x15 y34 w70 h20 c0x8888aa", "Sequência:")
seqLabel.SetFont("s9", "Segoe UI")

global seqText := osd.AddText("x90 y30 w800 h30 c0x00d4ff", "aguardando...")
seqText.SetFont("s16 Bold", MONO_FONT)

global hintText := osd.AddText("x670 y34 w235 h20 Right c0x666688", "Espaço / \ para confirmar")
hintText.SetFont("s9 Italic", "Segoe UI")

global sepLine := osd.AddText("x15 y65 w890 h1 +Background0x222233", "")

; Coluna Esquerda: Guia de Teclas
global guideHeader := osd.AddText("x15 y75 w218 h20 c0xFFD700", "GUIA DE TECLAS (Próxima)")
guideHeader.SetFont("s9 Bold", "Segoe UI")

global cards := Map()

CreateKeyCards() {
    global osd, cards
    cardCoords := Map(
        "Q",     {x: 15,  y: 95},
        "Right", {x: 128, y: 95},
        "A",     {x: 15,  y: 158},
        "Enter", {x: 128, y: 158}
    )
    for key, coord in cardCoords {
        cards[key] := CreateKeyCard(osd, key, coord.x, coord.y)
    }
}
CreateKeyCards()

; Coluna Direita: Tab Control com Mapas de Referência
global mapTab := osd.Add("Tab3", "x255 y75 w650 h480 cWhite +Background0x12121e", ["Geral", "Sílabas", "Triplas"])
mapTab.SetFont("s9 Bold", "Segoe UI")

mapTab.UseTab(1)
global t1c1 := osd.AddText("x265 y105 w300 h440 c0xaaaacc", osdGeral1)
t1c1.SetFont("s9", MONO_FONT)
global t1c2 := osd.AddText("x575 y105 w310 h440 c0xaaaacc", osdGeral2)
t1c2.SetFont("s9", MONO_FONT)

mapTab.UseTab(2)
global t2c1 := osd.AddText("x265 y105 w600 h440 c0xaaaacc", osdSyllables)
t2c1.SetFont("s9", MONO_FONT)

mapTab.UseTab(3)
global t3c1 := osd.AddText("x265 y105 w600 h440 c0xaaaacc", osdTriples)
t3c1.SetFont("s9", MONO_FONT)
mapTab.UseTab()

; Rodapé
global footerText := osd.AddText("x15 y570 w890 h20 Center c0x444455", "Modo Morse Keyboard - Projetado para digitação simplificada de 4 teclas")
footerText.SetFont("s8 Italic", "Segoe UI")

TabGoLeft() {
    global mapTab, showMaps
    if !showMaps
        return
    current := mapTab.Value
    if current > 1
        mapTab.Value := current - 1
    else
        mapTab.Value := 3
    UpdateOSD()
}

TabGoRight() {
    global mapTab, showMaps
    if !showMaps
        return
    current := mapTab.Value
    if current < 3
        mapTab.Value := current + 1
    else
        mapTab.Value := 1
    UpdateOSD()
}

ToggleMaps() {
    global showMaps, mapTab, osd, t1c1, t1c2, t2c1, t3c1, footerText
    showMaps := !showMaps
    
    if showMaps {
        mapTab.Visible := true
        activeTab := mapTab.Value
        t1c1.Visible := (activeTab = 1)
        t1c2.Visible := (activeTab = 1)
        t2c1.Visible := (activeTab = 2)
        t3c1.Visible := (activeTab = 3)
        footerText.Visible := true
    } else {
        mapTab.Visible := false
        t1c1.Visible := false
        t1c2.Visible := false
        t2c1.Visible := false
        t3c1.Visible := false
        footerText.Visible := false
    }
    
    UpdateOSD()
}

ToggleBrowserMode() {
    global USE_BROWSER_OSD, osd, osdWord, osdMini
    USE_BROWSER_OSD := !USE_BROWSER_OSD
    if USE_BROWSER_OSD {
        ; Esconder tudo ao ativar modo navegador
        osd.Hide()
        osdMini.Hide()
        ToolTip("Modo Navegador ATIVO ─ http://localhost:8766", A_ScreenWidth/2 - 200, A_ScreenHeight/2 - 30)
    } else {
        ToolTip("Modo OSD ATIVO", A_ScreenWidth/2 - 100, A_ScreenHeight/2 - 30)
    }
    SetTimer(() => ToolTip(), -1800)
    UpdateOSD()
}

GetCaretOrMousePos(&targetX, &targetY, w, h) {
    CoordMode("Caret", "Screen")
    if CaretGetPos(&caretX, &caretY) {
        targetX := caretX
        targetY := caretY + 20
    } else {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&mouseX, &mouseY)
        targetX := mouseX
        targetY := mouseY + 20
    }
    
    ; Ajustar limites da tela
    screenW := A_ScreenWidth
    screenH := A_ScreenHeight
    
    if targetX + w > screenW
        targetX := screenW - w
    if targetX < 0
        targetX := 0
        
    if targetY + h > screenH
        targetY := screenH - h
    if targetY < 0
        targetY := 0
}

UpdateOSD() {
    global morseActive, currentSequence, statusText, seqText, hintText, showMaps, visualBuffer
    global osd, osdMini, miniStatus, sepLine, USE_BROWSER_OSD

    ; Formata o texto de exibição (usado por OSD e navegador)
    displayText := ""
    if morseActive {
        if currentSequence != "" {
            if visualBuffer != "" {
                displayText := visualBuffer . " + [ " . FormatSequence(currentSequence) . " ]"
            } else {
                displayText := "[ " . FormatSequence(currentSequence) . " ]"
            }
        } else {
            if visualBuffer != "" {
                suggestion := GetAutocompleteSuggestion(visualBuffer)
                if (suggestion != "") {
                    displayText := "Acumulado: " . visualBuffer . " -> [Enter: " . suggestion . "]"
                } else {
                    displayText := "Acumulado: " . visualBuffer
                }
            } else {
                displayText := "aguardando..."
            }
        }
    }

    if USE_BROWSER_OSD {
        ; Modo Navegador: esconder todas as janelas OSD
        osd.Hide()
        osdMini.Hide()
    } else {
        ; Modo OSD clássico
        if morseActive {
            osdMini.Hide()

            ; Atualiza os textos nas GUIs
            seqText.Text := displayText
            if currentSequence != "" {
                hintText.Text := GetPossibleMatches(currentSequence)
            } else {
                hintText.Text := "Confirmar: Enter   |   Abas: w/s   |   Mapas: d"
            }

            ; Atualizar o guia de teclas dinâmico
            UpdateKeyGuide(currentSequence)

            ; Mostrar OSD principal de guia
            if showMaps {
                statusText.Opt("w820")
                statusText.Text := "⌨ MORSE KEYBOARD: ATIVO"
                seqText.Opt("w500")
                hintText.Visible := true
                sepLine.Opt("w820")
                try osd.Show("x10 y10 w890 h600 NoActivate")
                try WinSetTransparent(220, osd)
            } else {
                statusText.Opt("w220")
                statusText.Text := "⌨ MORSE KB: ATIVO"
                seqText.Opt("w140")
                hintText.Visible := false
                sepLine.Opt("w220")
                try osd.Show("x10 y10 w250 h230 NoActivate")
                try WinSetTransparent(220, osd)
            }

            statusText.Redraw()
            seqText.Redraw()
            sepLine.Redraw()
        } else {
            osd.Hide()
            miniStatus.Text := "⌨ MORSE KB: OFF"
            try osdMini.Show("x10 y10 NoActivate")
        }
    }

    ; Sempre sincronizar com o servidor Python (alimenta o navegador)
    SendStateToPython()
}

