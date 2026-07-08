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
        return "▲"
    if val = "{Down}"
        return "▼"
    if val = "{Left}"
        return "◀"
    if val = "{Right}"
        return "▶"
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
    card := guiObj.AddText("x" . x . " y" . y . " w50 h50 +Background0x1c1c2e +Border", "")
    label := guiObj.AddText("x" . (x+2) . " y" . (y+2) . " w46 h15 Center +BackgroundTrans c0x9999bb", keyName)
    label.SetFont("s8 Bold", "Segoe UI")
    val := guiObj.AddText("x" . (x+2) . " y" . (y+18) . " w46 h30 Center +BackgroundTrans cWhite", "")
    val.SetFont("s10 Bold", "Consolas")
    return {card: card, label: label, val: val}
}

UpdateCard(key, valText, isActive) {
    global cards
    cardObj := cards[key]
    
    if isActive {
        cardObj.card.Opt("+Background0x1c1c2e")
        cardObj.label.Opt("c0x9999bb")
        cardObj.val.Opt("c0x00FFCC")
        cardObj.val.Text := valText
    } else {
        cardObj.card.Opt("+Background0x0b0b14")
        cardObj.label.Opt("c0x222233")
        cardObj.val.Opt("c0x222233")
        cardObj.val.Text := "-"
    }
    cardObj.card.Redraw()
    cardObj.label.Redraw()
    cardObj.val.Redraw()
}

UpdateKeyGuide(seq) {
    global traditionalMode
    keyMapping := Map("Q", "Q", "A", "A", "R", "R")
    if (traditionalMode) {
        cards["A"].label.Text := "."
        cards["R"].label.Text := "-"
    } else {
        cards["A"].label.Text := "A"
        cards["R"].label.Text := "R"
    }
    
    for k, cardKey in keyMapping {
        nextSeq := seq . k
        global morseMap
        val := morseMap.Has(nextSeq) ? morseMap[nextSeq] : "NOT_FOUND"
        
        if (val != "NOT_FOUND" && val != "") {
            formattedVal := FormatForCard(val)
            UpdateCard(cardKey, formattedVal, true)
        } else {
            ; Como o mapa de atalhos não fica mais na memória para consultar os prefixos,
            ; exibimos "-" (inativo) sempre que não for o atalho exato.
            UpdateCard(cardKey, "-", false)
        }
    }
    UpdateCard("Ent", "Conf", true)
}

global osdPosX := IniRead(A_ScriptDir . "\osd_pos.ini", "Position", "X", 10)
global osdPosY := IniRead(A_ScriptDir . "\osd_pos.ini", "Position", "Y", 10)

OnMessage(0x0201, WM_LBUTTONDOWN)
WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    global osd, osdMini, osdPosX, osdPosY
    if (hwnd == osd.Hwnd || hwnd == osdMini.Hwnd) {
        SendMessage(0xA1, 2, , , "ahk_id " hwnd)
        
        ; Save the new position
        if (hwnd == osd.Hwnd) {
            osd.GetPos(&X, &Y)
            try osdMini.Move(X, Y)
        } else {
            osdMini.GetPos(&X, &Y)
            try osd.Move(X, Y)
        }
        
        IniWrite(X, A_ScriptDir . "\osd_pos.ini", "Position", "X")
        IniWrite(Y, A_ScriptDir . "\osd_pos.ini", "Position", "Y")
        
        ; Keep them synced
        osdPosX := X
        osdPosY := Y
    }
}

; ── GUI pequena (OFF) ──
global osdMini := Gui("+AlwaysOnTop -Caption +ToolWindow +Resize")
osdMini.Show("Hide x" . osdPosX . " y" . osdPosY)
osdMini.BackColor := "0x12121e"
osdMini.MarginX := 10
osdMini.MarginY := 6

global miniStatus := osdMini.AddText("cWhite w200 Center", "⌨ MORSE KB: OFF")
miniStatus.SetFont("s10 Bold", "Segoe UI")

global miniHint := osdMini.AddText("c0x555577 w200 Center", "CapsLock para ativar")
miniHint.SetFont("s8", "Segoe UI")

osdMini.Show("NoActivate")
WinSetTransparent(220, osdMini)

; ── GUI completa (ON) ──
global osd := Gui("+AlwaysOnTop -Caption +ToolWindow +Resize", "MorseGuideOSD")
osd.Show("Hide x" . osdPosX . " y" . osdPosY)
osd.BackColor := "0x0b0b14"
osd.MarginX := 10
osd.MarginY := 10

; Status e Informações da Sequência
global statusText := osd.AddText("x15 y10 w1260 h28 c0x00FFCC", "⌨ MORSE KEYBOARD: ATIVO")
statusText.SetFont("s14 Bold", "Segoe UI")

global seqLabel := osd.AddText("x15 y38 w80 h24 c0x8888aa", "Sequência:")
seqLabel.SetFont("s11", "Segoe UI")

global seqText := osd.AddText("x100 y34 w800 h36 c0x00d4ff", "aguardando...")
seqText.SetFont("s20 Bold", MONO_FONT)

global hintText := osd.AddText("x1000 y38 w260 h24 Right c0x666688", "1 / Enter para confirmar")
hintText.SetFont("s11 Italic", "Segoe UI")

global sepLine := osd.AddText("x15 y75 w1260 h1 +Background0x222233", "")

global cards := Map()
CreateKeyCards() {
    global osd, cards
    cards["Q"] := CreateKeyCard(osd, "Q", 15, 85)
    cards["A"] := CreateKeyCard(osd, "A", 70, 85)
    cards["R"] := CreateKeyCard(osd, "R", 15, 140)
    cards["Ent"] := CreateKeyCard(osd, "Enter", 70, 140)
}
CreateKeyCards()

; Colunas dinâmicas (4 colunas lado a lado)
LoadColumns() {
    global osdGeral1, osdGeral2
    
    col1 := "", col2 := "", col3 := "", col4 := ""
    
    lines1 := StrSplit(osdGeral1, "`n", "`r")
    for index, line in lines1 {
        if index <= 17
            col1 .= line . "`n"
        else if index >= 19 && index <= 36
            col2 .= line . "`n"
    }
    
    lines2 := StrSplit(osdGeral2, "`n", "`r")
    for index, line in lines2 {
        if index <= 15
            col3 .= line . "`n"
        else if index >= 16 && index <= 31
            col4 .= line . "`n"
    }
    
    global t1c1 := osd.AddText("x140 y85 w190 h300 c0xaaaacc", col1)
    t1c1.SetFont("s11 Bold", MONO_FONT)
    global t1c2 := osd.AddText("x350 y85 w290 h300 c0xaaaacc", col2)
    t1c2.SetFont("s11 Bold", MONO_FONT)
    global t1c3 := osd.AddText("x660 y85 w285 h300 c0xaaaacc", col3)
    t1c3.SetFont("s11 Bold", MONO_FONT)
    global t1c4 := osd.AddText("x965 y85 w340 h300 c0xaaaacc", col4)
    t1c4.SetFont("s11 Bold", MONO_FONT)
}
LoadColumns()

ToggleMaps() {
    global showMaps, osd, t1c1, t1c2, t1c3, t1c4
    showMaps := !showMaps
    
    if showMaps {
        t1c1.Visible := true
        t1c2.Visible := true
        t1c3.Visible := true
        t1c4.Visible := true
    } else {
        t1c1.Visible := false
        t1c2.Visible := false
        t1c3.Visible := false
        t1c4.Visible := false
    }
    UpdateOSD()
}

ToggleBrowserMode() {
    global USE_BROWSER_OSD, osd, osdMini
    USE_BROWSER_OSD := !USE_BROWSER_OSD
    if USE_BROWSER_OSD {
        osd.Hide()
        osdMini.Hide()
        ToolTip("Modo Navegador ATIVO ─ http://localhost:8766", A_ScreenWidth/2 - 200, A_ScreenHeight/2 - 30)
    } else {
        ToolTip("Modo OSD ATIVO", A_ScreenWidth/2 - 100, A_ScreenHeight/2 - 30)
    }
    SetTimer(() => ToolTip(), -1800)
    UpdateOSD()
}

UpdateOSD() {
    global morseActive, currentSequence, statusText, seqText, hintText, showMaps, visualBuffer
    global osd, osdMini, miniStatus, sepLine, USE_BROWSER_OSD

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
        osd.Hide()
        osdMini.Hide()
    } else {
        if morseActive {
            osdMini.Hide()
            seqText.Text := displayText
            if currentSequence != "" {
                hintText.Text := GetPossibleMatches(currentSequence)
            } else {
                hintText.Text := "Confirmar: Enter | Mapas: d"
            }
            UpdateKeyGuide(currentSequence)

            if showMaps {
                statusText.Opt("w1260")
                statusText.Text := "⌨ MORSE KEYBOARD: ATIVO"
                seqText.Opt("w800")
                hintText.Visible := true
                sepLine.Opt("w1260")
                try osd.Show("w1300 h390 NoActivate")
                try WinSetTransparent(220, osd)
            } else {
                statusText.Opt("w220")
                statusText.Text := "⌨ MORSE KB: ATIVO"
                seqText.Opt("w140")
                hintText.Visible := false
                sepLine.Opt("w220")
                try osd.Show("w250 h195 NoActivate")
                try WinSetTransparent(220, osd)
            }
            statusText.Redraw()
            seqText.Redraw()
            sepLine.Redraw()
        } else {
            osd.Hide()
            miniStatus.Text := "⌨ MORSE KB: OFF"
            try osdMini.Show("NoActivate")
        }
    }
    SendStateToPython()
}
